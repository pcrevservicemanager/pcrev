import os, re, secrets
from contextlib import contextmanager
from datetime import datetime
from functools import wraps
from dotenv import load_dotenv
from flask import Flask, render_template, request, redirect, url_for, abort, session, g
from werkzeug.security import generate_password_hash, check_password_hash
import pymysql, pymysql.cursors
import qrcode, qrcode.image.svg

load_dotenv()
app = Flask(__name__)
app.secret_key = os.getenv("SECRET_KEY") or "dev-only-change-me"
app.config.update(SESSION_COOKIE_SAMESITE="Lax")

STATUSES = ["Received", "Diagnosing", "Waiting for Parts", "Repairing", "Ready for Pickup", "Released"]
PENDING = ["Received", "Diagnosing", "Waiting for Parts", "Repairing"]   # what a technician sees
CATEGORIES = ["New Customer", "Referral", "Repeat Customer"]
CHECKLIST = ["Speaker", "Keyboard", "USB Ports", "Charging", "Touchpad", "WiFi Connections", "LCD", "Battery", "Fan", "Camera"]

TECH = "Technical In-Charge"
ROLES = ["Admin", TECH, "Service Manager", "HR"]
# Change what each role can do here.
ROLE_PERMS = {
    "Admin":           {"jobs_all", "jobs_edit", "users", "users_admin"},
    "Service Manager": {"jobs_all", "jobs_edit"},
    TECH:              {"jobs_own"},          # only their own pending jobs
    "HR":              {"users"},             # staff accounts only
}

# Add a module here when it is ready: set live=True and create its routes.
MODULES = [
    {"key": "joborders", "label": "Job Orders", "endpoint": "job_list", "live": True, "perms": ("jobs_all", "jobs_own")},
    {"key": "tickets",   "label": "Ticketing",  "endpoint": "module_soon", "live": False, "perms": ("jobs_all",)},
    {"key": "inventory", "label": "Inventory",  "endpoint": "module_soon", "live": False, "perms": ("jobs_all",)},
    {"key": "pos",       "label": "Point of Sale", "endpoint": "module_soon", "live": False, "perms": ("jobs_all",)},
]


# ---------------- database ----------------
@contextmanager
def cursor():
    """Open a MySQL connection, commit on success, roll back on error."""
    conn = pymysql.connect(
        host=os.getenv("DB_HOST", "localhost"), port=int(os.getenv("DB_PORT", "3306")),
        user=os.getenv("DB_USER", "root"), password=os.getenv("DB_PASSWORD", ""),
        database=os.getenv("DB_NAME", "pcrevolution"), charset="utf8mb4",
        cursorclass=pymysql.cursors.DictCursor)
    try:
        with conn.cursor() as cur:
            yield cur
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


# ---------------- auth helpers ----------------
def can(*perms):
    u = g.get("user")
    return bool(u) and any(p in ROLE_PERMS.get(u["role"], ()) for p in perms)


def require(*perms):
    """Login required; if perms are given, the user needs at least one of them."""
    def deco(f):
        @wraps(f)
        def wrapper(*a, **k):
            if not g.user:
                return redirect(url_for("login", next=request.path))
            if perms and not can(*perms):
                abort(403)
            return f(*a, **k)
        return wrapper
    return deco


def pwhash(pw):
    return generate_password_hash(pw, method="pbkdf2:sha256")


def check_user_input(name, username, pw, need_pw):
    if not name:
        return "Enter the full name."
    if not re.fullmatch(r"[a-z0-9._-]{3,30}", username):
        return "Username needs 3 to 30 letters, numbers, dots, dashes or underscores."
    if (need_pw or pw) and len(pw) < 8:
        return "Password needs at least 8 characters."
    return None


@app.before_request
def load_user():
    g.user = None
    if request.endpoint in (None, "static"):
        return
    uid = session.get("uid")
    if uid:
        with cursor() as cur:
            cur.execute("SELECT id, username, full_name, role FROM users WHERE id=%s AND active=1", (uid,))
            g.user = cur.fetchone()
        if not g.user:
            session.clear()
    if request.method == "POST":
        tok = session.get("csrf")
        sent = request.form.get("csrf", "")
        if not tok or not secrets.compare_digest(sent.encode(), tok.encode()):
            abort(400)


@app.context_processor
def inject():
    def mod_url(m):
        return url_for(m["endpoint"], key=m["key"]) if m["endpoint"] == "module_soon" else url_for(m["endpoint"])

    def csrf():
        if "csrf" not in session:
            session["csrf"] = secrets.token_hex(16)
        return session["csrf"]
    return {"modules": MODULES, "statuses": STATUSES, "mod_url": mod_url, "can": can, "csrf": csrf, "me": g.get("user")}


@app.errorhandler(403)
def forbidden(e):
    return render_template("error.html", code=403, msg="Your role does not have access to this page."), 403


# ---------------- job helpers ----------------
def scope():
    """SQL limiting which job orders the signed-in user may see."""
    if can("jobs_all"):
        return "", []
    marks = ",".join(["%s"] * len(PENDING))
    return f" AND tech_user_id=%s AND status IN ({marks})", [g.user["id"]] + PENDING


def fetch_job(cur, jid):
    s, a = scope()
    cur.execute("SELECT *, id AS job_no FROM job_orders WHERE id=%s" + s, [jid] + a)
    return cur.fetchone() or abort(404)


def split_checklist(row):
    row["checklist"] = [x for x in (row.get("checklist") or "").split(",") if x]
    return row


def qr_svg(url):
    img = qrcode.make(url, image_factory=qrcode.image.svg.SvgPathImage, box_size=10)
    return img.to_string().decode().split("?>")[-1]


@app.template_filter("jobno")
def jobno(n):
    return f"{n:05d}"


# ---------------- sign in / setup ----------------
def user_count():
    with cursor() as cur:
        cur.execute("SELECT COUNT(*) AS n FROM users")
        return cur.fetchone()["n"]


@app.route("/setup", methods=["GET", "POST"])
def setup():
    """First run only: create the first Admin account."""
    if user_count() > 0:
        abort(404)
    error = None
    if request.method == "POST":
        f = request.form
        name, username, pw = f.get("full_name", "").strip(), f.get("username", "").strip().lower(), f.get("password", "")
        error = check_user_input(name, username, pw, need_pw=True)
        if not error:
            with cursor() as cur:
                cur.execute("INSERT INTO users (username, full_name, password_hash, role) VALUES (%s,%s,%s,'Admin')",
                            (username, name, pwhash(pw)))
            return redirect(url_for("login"))
    return render_template("auth.html", mode="setup", error=error, form=request.form)


@app.route("/login", methods=["GET", "POST"])
def login():
    if user_count() == 0:
        return redirect(url_for("setup"))
    error = None
    if request.method == "POST":
        with cursor() as cur:
            cur.execute("SELECT * FROM users WHERE username=%s AND active=1",
                        (request.form.get("username", "").strip().lower(),))
            u = cur.fetchone()
        if u and check_password_hash(u["password_hash"], request.form.get("password", "")):
            session.clear()
            session["uid"] = u["id"]
            nxt = request.args.get("next", "")
            ok = nxt.startswith("/") and not nxt.startswith("//") and "\\" not in nxt
            return redirect(nxt if ok else url_for("dashboard"))
        error = "Wrong username or password."
    return render_template("auth.html", mode="login", error=error, form=request.form)


@app.post("/logout")
def logout():
    session.clear()
    return redirect(url_for("login"))


@app.route("/account", methods=["GET", "POST"])
@require()
def account():
    msg = error = None
    if request.method == "POST":
        f = request.form
        with cursor() as cur:
            cur.execute("SELECT password_hash FROM users WHERE id=%s", (g.user["id"],))
            row = cur.fetchone()
            new = f.get("new", "")
            if not check_password_hash(row["password_hash"], f.get("current", "")):
                error = "Your current password is not correct."
            elif len(new) < 8:
                error = "Password needs at least 8 characters."
            elif new != f.get("confirm", ""):
                error = "The two new passwords do not match."
            else:
                cur.execute("UPDATE users SET password_hash=%s WHERE id=%s", (pwhash(new), g.user["id"]))
                msg = "Password changed."
    return render_template("account.html", msg=msg, error=error)


# ---------------- staff registration (Admin and HR) ----------------
@app.route("/users")
@require("users")
def user_list():
    with cursor() as cur:
        cur.execute("""SELECT id, username, full_name, role, active, created_at FROM users
                       ORDER BY FIELD(role,'Admin','Service Manager','Technical In-Charge','HR'), full_name""")
        rows = cur.fetchall()
    for r in rows:
        r["editable"] = can("users_admin") or r["role"] != "Admin"   # HR cannot touch Admin accounts
    return render_template("users.html", rows=rows)


@app.route("/users/new", methods=["GET", "POST"])
@app.route("/users/<int:uid>/edit", methods=["GET", "POST"])
@require("users")
def user_form(uid=None):
    roles = ROLES if can("users_admin") else [r for r in ROLES if r != "Admin"]
    user = None
    if uid:
        with cursor() as cur:
            cur.execute("SELECT * FROM users WHERE id=%s", (uid,))
            user = cur.fetchone() or abort(404)
        if user["role"] == "Admin" and not can("users_admin"):
            abort(403)
    is_self = bool(user) and user["id"] == g.user["id"]
    error, u = None, (user or {"active": 1})
    if request.method == "POST":
        f = request.form
        name, username, pw = f.get("full_name", "").strip(), f.get("username", "").strip().lower(), f.get("password", "")
        role = user["role"] if is_self else f.get("role")          # nobody can demote or lock out themselves
        active = 1 if is_self else (1 if f.get("active") else 0)
        if role not in roles:
            abort(403)
        error = check_user_input(name, username, pw, need_pw=not uid)
        u = {"full_name": name, "username": username, "role": role, "active": active}
        if not error:
            try:
                with cursor() as cur:
                    if uid and pw:
                        cur.execute("UPDATE users SET full_name=%s, username=%s, role=%s, active=%s, password_hash=%s WHERE id=%s",
                                    (name, username, role, active, pwhash(pw), uid))
                    elif uid:
                        cur.execute("UPDATE users SET full_name=%s, username=%s, role=%s, active=%s WHERE id=%s",
                                    (name, username, role, active, uid))
                    else:
                        cur.execute("INSERT INTO users (username, full_name, password_hash, role, active) VALUES (%s,%s,%s,%s,%s)",
                                    (username, name, pwhash(pw), role, active))
                return redirect(url_for("user_list"))
            except pymysql.err.IntegrityError:
                error = "That username is already taken."
    return render_template("user_form.html", u=u, uid=uid, roles=roles, is_self=is_self, error=error)


# ---------------- dashboard ----------------
@app.route("/")
@require()
def dashboard():
    counts, recent, staff = {}, [], None
    show_jobs = can("jobs_all", "jobs_own")
    with cursor() as cur:
        if show_jobs:
            s, a = scope()
            cur.execute("SELECT status, COUNT(*) AS n FROM job_orders WHERE 1=1" + s + " GROUP BY status", a)
            counts = {r["status"]: r["n"] for r in cur.fetchall()}
            cur.execute("SELECT *, id AS job_no FROM job_orders WHERE 1=1" + s + " ORDER BY id DESC LIMIT 6", a)
            recent = cur.fetchall()
        if can("users"):
            cur.execute("SELECT COUNT(*) AS n FROM users WHERE active=1")
            staff = cur.fetchone()["n"]
    tally = STATUSES[:-1] if can("jobs_all") else PENDING
    open_jobs = sum(counts.get(s, 0) for s in tally)
    return render_template("dashboard.html", counts=counts, recent=recent, staff=staff,
                           show_jobs=show_jobs, tally=tally, open_jobs=open_jobs)


# ---------------- job orders ----------------
@app.route("/job-orders")
@require("jobs_all", "jobs_own")
def job_list():
    q = request.args.get("q", "").strip()
    status = request.args.get("status", "")
    s, args = scope()
    sql = "SELECT *, id AS job_no FROM job_orders WHERE 1=1" + s
    if q:
        sql += " AND (customer_name LIKE %s OR contact_number LIKE %s OR CAST(id AS CHAR) LIKE %s OR si_dr_number LIKE %s)"
        args += [f"%{q}%"] * 4
    if status:
        sql += " AND status = %s"
        args.append(status)
    sql += " ORDER BY id DESC LIMIT 200"
    with cursor() as cur:
        cur.execute(sql, args)
        rows = cur.fetchall()
    return render_template("job_list.html", rows=rows, q=q, status=status)


@app.route("/job-orders/new", methods=["GET", "POST"])
@app.route("/job-orders/<int:jid>/edit", methods=["GET", "POST"])
@require("jobs_edit")
def job_form(jid=None):
    job, items = None, [{"qty": 1, "description": "", "serial_no": "", "issue": ""}]
    with cursor() as cur:
        if jid:
            job = split_checklist(fetch_job(cur, jid))
            cur.execute("SELECT * FROM job_order_items WHERE job_order_id=%s ORDER BY id", (jid,))
            items = cur.fetchall() or items
        cur.execute("SELECT id, full_name FROM users WHERE role=%s AND (active=1 OR id=%s) ORDER BY full_name",
                    (TECH, job["tech_user_id"] if job and job["tech_user_id"] else 0))
        techs = cur.fetchall()
    if request.method == "POST":
        f = request.form
        released_at = (f.get("released_at") or "").replace("T", " ") or None
        tech_id = int(f["tech_user_id"]) if f.get("tech_user_id", "").isdigit() else None
        tech_name = next((t["full_name"] for t in techs if t["id"] == tech_id), None)
        if tech_name is None:
            tech_id = None
        vals = (
            f.get("client_category") or CATEGORIES[0], f["customer_name"].strip(), f.get("contact_number"),
            f.get("email"), f.get("fb_name"), f.get("si_dr_number"), f.get("years_of_unit"),
            {"yes": True, "no": False}.get(f.get("warranty")), f.get("purchase_date") or None,
            f.get("action_taken"), f.get("diagnosed_by"), tech_name,
            ",".join(f.getlist("checklist")), f.get("received_by"), f.get("released_to"),
            released_at, f.get("status") or STATUSES[0], tech_id,
        )
        rows = [
            (int(q or 1), d.strip(), s, i)
            for q, d, s, i in zip(f.getlist("qty"), f.getlist("description"), f.getlist("serial_no"), f.getlist("issue"))
            if d.strip()
        ]
        with cursor() as cur:
            if jid:
                cur.execute("""UPDATE job_orders SET client_category=%s, customer_name=%s, contact_number=%s,
                    email=%s, fb_name=%s, si_dr_number=%s, years_of_unit=%s, warranty=%s, purchase_date=%s,
                    action_taken=%s, diagnosed_by=%s, tech_assigned=%s, checklist=%s, received_by=%s,
                    released_to=%s, released_at=%s, status=%s, tech_user_id=%s WHERE id=%s""", vals + (jid,))
                cur.execute("DELETE FROM job_order_items WHERE job_order_id=%s", (jid,))
            else:
                cur.execute("""INSERT INTO job_orders (client_category, customer_name, contact_number, email,
                    fb_name, si_dr_number, years_of_unit, warranty, purchase_date, action_taken, diagnosed_by,
                    tech_assigned, checklist, received_by, released_to, released_at, status, tech_user_id, status_token)
                    VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)""",
                    vals + (secrets.token_urlsafe(8),))
                jid = cur.lastrowid
            if rows:
                cur.executemany(
                    "INSERT INTO job_order_items (job_order_id, qty, description, serial_no, issue) VALUES (%s,%s,%s,%s,%s)",
                    [(jid,) + r for r in rows])
        return redirect(url_for("job_view", jid=jid))
    return render_template("job_form.html", job=job, items=items, categories=CATEGORIES,
                           checklist=CHECKLIST, techs=techs, now=datetime.now())


@app.route("/job-orders/<int:jid>")
@require("jobs_all", "jobs_own")
def job_view(jid):
    with cursor() as cur:
        job = split_checklist(fetch_job(cur, jid))
        cur.execute("SELECT * FROM job_order_items WHERE job_order_id=%s ORDER BY id", (jid,))
        items = cur.fetchall()
    url = os.getenv("PUBLIC_URL", request.host_url.rstrip("/")) + url_for("public_status", token=job["status_token"])
    return render_template("job_view.html", job=job, items=items, qr=qr_svg(url),
                           categories=CATEGORIES, checklist=CHECKLIST)


@app.route("/job-orders/<int:jid>/work", methods=["GET", "POST"])
@require("jobs_own")
def job_work(jid):
    """Technician's update page: action taken, checklist and status of their own job."""
    work_statuses = PENDING + ["Ready for Pickup"]
    with cursor() as cur:
        job = split_checklist(fetch_job(cur, jid))
        cur.execute("SELECT * FROM job_order_items WHERE job_order_id=%s ORDER BY id", (jid,))
        items = cur.fetchall()
        if request.method == "POST":
            f = request.form
            status = f.get("status")
            if status not in work_statuses:
                abort(400)
            cur.execute("UPDATE job_orders SET action_taken=%s, checklist=%s, status=%s WHERE id=%s",
                        (f.get("action_taken"), ",".join(f.getlist("checklist")), status, jid))
            return redirect(url_for("job_list"))
    return render_template("job_work.html", job=job, items=items, checklist=CHECKLIST, work_statuses=work_statuses)


@app.post("/job-orders/<int:jid>/status")
@require("jobs_all", "jobs_own")
def job_status(jid):
    s = request.form["status"]
    if s not in STATUSES or (s == "Released" and not can("jobs_edit")):
        abort(400)
    with cursor() as cur:
        fetch_job(cur, jid)    # enforces who may touch this job
        cur.execute("UPDATE job_orders SET status=%s, released_at = CASE WHEN %s='Released' THEN NOW() ELSE released_at END WHERE id=%s",
                    (s, s, jid))
    if not can("jobs_all"):    # a technician's job may leave their list after the change
        return redirect(url_for("job_list"))
    return redirect(request.referrer or url_for("job_view", jid=jid))


@app.route("/status/<token>")
def public_status(token):
    """Customer-facing page opened by the QR code on the printed job order."""
    with cursor() as cur:
        cur.execute("SELECT id AS job_no, customer_name, status, created_at FROM job_orders WHERE status_token=%s", (token,))
        job = cur.fetchone() or abort(404)
    return render_template("public_status.html", job=job)


# ---------------- modules to follow ----------------
@app.route("/coming-soon/<key>")
@require("jobs_all")
def module_soon(key):
    m = next((m for m in MODULES if m["key"] == key), None) or abort(404)
    return render_template("module_soon.html", m=m)


if __name__ == "__main__":
    app.run(debug=True)
