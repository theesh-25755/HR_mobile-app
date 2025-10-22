from datetime import datetime
from flask import Flask, request, jsonify
import bcrypt
from flask_jwt_extended import (
    JWTManager, create_access_token, jwt_required,
    get_jwt_identity, get_jwt
)
from flask_cors import CORS
from pymongo import MongoClient
from bson import ObjectId
import base64
import certifi
from werkzeug.utils import secure_filename

# -------------------------
# Flask app setup
# -------------------------
app = Flask(__name__)
CORS(app)

app.config['JWT_SECRET_KEY'] = 'your-secret-key'
jwt = JWTManager(app)

# -------------------------
# MongoDB Atlas Connection
# -------------------------
ca = certifi.where()

client = MongoClient(
    "mongodb+srv://database001:database123@cluster001.ptbnw11.mongodb.net/?retryWrites=true&w=majority&appName=Cluster001",
    tlsCAFile=ca  # <-- Add this line
)

db = client["database001"]
users_collection = db["usersdata"]
leave_collection = db["leave_applications"]
notifications_collection = db["notifications"]

# -------------------------
# Register Route
# -------------------------
@app.route('/register', methods=['POST'])
def register():
    data = request.get_json()
    email = data.get("email")
    password = data.get("password")
    role = data.get("role", "employee").lower()
    name = data.get("name", email.split('@')[0])

    if not email or not password:
        return jsonify({"message": "Email and password are required"}), 400

    if users_collection.find_one({"email": email}):
        return jsonify({"message": "User already exists"}), 400

    hashed_pw = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt())

    users_collection.insert_one({
        "email": email,
        "password": hashed_pw,
        "role": role,
        "name": name
    })

    return jsonify({"message": "User registered successfully!"}), 201

# -------------------------
# Login Route
# -------------------------
@app.route('/login', methods=['POST'])
def login():
    data = request.get_json()
    email = data.get('email')
    password = data.get('password')

    if not email or not password:
        return jsonify({"message": "Email and password are required"}), 400

    user = users_collection.find_one({"email": email})
    if user is None:
        return jsonify({"message": "User not found"}), 404

    stored_pw = user['password']
    if isinstance(stored_pw, str):
        stored_pw = stored_pw.encode('utf-8')
    if bcrypt.checkpw(password.encode('utf-8'), stored_pw):
        role = user.get("role", "employee").lower()
        name = user.get("name", email.split('@')[0])

        access_token = create_access_token(
            identity=email,
            additional_claims={"role": role, "name": name}
        )

        return jsonify({
            "message": "Login successful",
            "access_token": access_token,
            "user": {"email": email, "role": role, "name": name}
        }), 200
    else:
        return jsonify({"message": "Invalid password"}), 401

# -------------------------
# Protected Profile Route
# -------------------------
@app.route('/profile', methods=['GET'])
@jwt_required()
def profile():
    current_user_email = get_jwt_identity()
    claims = get_jwt()
    return jsonify({
        "user": {
            "email": current_user_email,
            "role": claims.get("role", "employee"),
            "name": claims.get("name", "")
        }
    })

# -------------------------
# Get user profile
# -------------------------
@app.route('/user-profile', methods=['GET'])
@jwt_required()
def get_user_profile():
    email = get_jwt_identity()
    user = users_collection.find_one({"email": email}, {"password": 0})
    if not user:
        return jsonify({"message": "User not found"}), 404

    if "profile_image" in user and user["profile_image"]:
        profile_image = user["profile_image"]
    else:
        profile_image = None

    user["_id"] = str(user["_id"])
    user["profile_image"] = profile_image
    return jsonify(user), 200

# -------------------------
# Update user profile
# -------------------------
@app.route('/user-profile', methods=['PUT'])
@jwt_required()
def update_user_profile():
    email = get_jwt_identity()
    data = request.get_json(force=True, silent=True)
    if not data:
        return jsonify({"message": "No data provided"}), 400

    allowed_fields = ["name", "phone", "department"]
    update_data = {k: v for k, v in data.items() if k in allowed_fields}
    if not update_data:
        return jsonify({"message": "No valid fields to update"}), 400

    result = users_collection.update_one({"email": email}, {"$set": update_data})
    if result.matched_count == 0:
        return jsonify({"message": "User not found"}), 404

    return jsonify({"message": "Profile updated successfully"}), 200

# -------------------------
# Upload profile image
# -------------------------
@app.route('/user-profile/photo', methods=['POST'])
@jwt_required()
def upload_profile_photo():
    try:
        email = get_jwt_identity()
        if 'profileImage' not in request.files:
            return jsonify({"message": "No file part named 'profileImage'"}), 400

        file = request.files['profileImage']
        if file.filename == '':
            return jsonify({"message": "No selected file"}), 400

        filename = secure_filename(file.filename)
        mime_type = file.mimetype or "application/octet-stream"
        file_bytes = file.read()
        encoded = base64.b64encode(file_bytes).decode('utf-8')
        data_url = f"data:{mime_type};base64,{encoded}"

        result = users_collection.update_one(
            {"email": email},
            {"$set": {
                "profile_image": data_url,
                "profile_image_filename": filename,
                "profile_image_updatedAt": datetime.utcnow().isoformat()
            }}
        )
        if result.matched_count == 0:
            return jsonify({"message": "User not found"}), 404

        return jsonify({"message": "Profile image uploaded", "profile_image": data_url}), 200

    except Exception as e:
        return jsonify({"message": f"Server error: {str(e)}"}), 500

# -------------------------
# Get all users (admin only)
# -------------------------
@app.route("/users", methods=["GET"])
@jwt_required()
def get_users():
    claims = get_jwt()
    if claims.get("role") not in ["super_admin", "hr_manager"]:
        return jsonify({"message": "Access denied"}), 403

    users = list(users_collection.find({}, {"password": 0}))
    for u in users:
        u["_id"] = str(u["_id"])
    return jsonify(users), 200

# -------------------------
# Leave Application Routes
# -------------------------
@app.route("/leave-application", methods=["POST"])
@jwt_required()
def leave_application():
    try:
        current_user_email = get_jwt_identity()
        claims = get_jwt()

        data = request.json
        if not data:
            return jsonify({"message": "Invalid request"}), 400

        leave_data = {
            "user_email": current_user_email,
            "user_name": claims.get("name"),
            "role": claims.get("role"),
            "leaveType": data.get("leaveType"),
            "fromDate": data.get("fromDate"),
            "toDate": data.get("toDate"),
            "reason": data.get("reason"),
            "halfDay": data.get("halfDay", False),
            "days": data.get("days"),
            "submittedAt": datetime.utcnow().isoformat(),
            "approvals": {
                "supervisor": "Pending",
                "project_manager": "Pending",
                "hr_manager": "Pending"
            },
            "finalStatus": "Pending",
            "history": [],
            "updatedAt": datetime.utcnow().isoformat()
        }

        res = leave_collection.insert_one(leave_data)
        return jsonify({"message": "Leave application submitted successfully!", "id": str(res.inserted_id)}), 201

    except Exception as e:
        return jsonify({"message": f"Server error: {str(e)}"}), 500

@app.route("/leave-applications/pending", methods=["GET"])
@jwt_required()
def get_pending_leaves():
    claims = get_jwt()
    role = claims.get("role")

    if role not in ["supervisor", "project_manager", "hr_manager"]:
        return jsonify({"message": "Access denied"}), 403

    base_query = {"finalStatus": "Pending"}

    if role == "supervisor":
        query = {**base_query, "approvals.supervisor": "Pending"}
    elif role == "project_manager":
        query = {
            **base_query,
            "approvals.supervisor": "Approved",
            "approvals.project_manager": "Pending"
        }
    else:
        query = {
            **base_query,
            "approvals.supervisor": "Approved",
            "approvals.project_manager": "Approved",
            "approvals.hr_manager": "Pending"
        }

    leaves = list(leave_collection.find(query).sort("submittedAt", -1))
    for leave in leaves:
        leave["_id"] = str(leave["_id"])
    return jsonify(leaves), 200

@app.route("/leave-applications/<leave_id>/action", methods=["POST"])
@jwt_required()
def approve_or_reject(leave_id):
    try:
        claims = get_jwt()
        role = claims.get("role")
        actor_email = get_jwt_identity()
        actor_name = claims.get("name")

        if role not in ["supervisor", "project_manager", "hr_manager"]:
            return jsonify({"message": "Access denied"}), 403

        data = request.json or {}
        action = data.get("action")
        comment = data.get("comment", "")

        if action not in ["Approved", "Rejected"]:
            return jsonify({"message": "Invalid action"}), 400

        leave = leave_collection.find_one({"_id": ObjectId(leave_id)})
        if not leave:
            return jsonify({"message": "Leave not found"}), 404

        if leave.get("finalStatus") != "Pending":
            return jsonify({"message": f"Leave already {leave.get('finalStatus')}"}), 400

        if role == "project_manager" and leave["approvals"]["supervisor"] != "Approved":
            return jsonify({"message": "Supervisor must approve first"}), 400
        if role == "hr_manager" and (
            leave["approvals"]["supervisor"] != "Approved" or
            leave["approvals"]["project_manager"] != "Approved"
        ):
            return jsonify({"message": "Project Manager must approve first"}), 400

        if leave["approvals"][role] != "Pending":
            return jsonify({"message": f"This request is already {leave['approvals'][role]} by {role}"}), 400

        updates = {
            f"approvals.{role}": action,
            "updatedAt": datetime.utcnow().isoformat()
        }

        history_entry = {
            "by_role": role,
            "by_email": actor_email,
            "by_name": actor_name,
            "action": action,
            "comment": comment,
            "at": datetime.utcnow().isoformat()
        }

        if action == "Rejected":
            updates["finalStatus"] = "Rejected"
            updates["rejectedBy"] = role
            updates["rejectedAt"] = datetime.utcnow().isoformat()
        else:
            new_approvals = leave["approvals"].copy()
            new_approvals[role] = "Approved"
            if all(v == "Approved" for v in new_approvals.values()):
                updates["finalStatus"] = "Approved"
                updates["approvedAt"] = datetime.utcnow().isoformat()

        leave_collection.update_one(
            {"_id": ObjectId(leave_id)},
            {
                "$set": updates,
                "$push": {"history": history_entry}
            }
        )

        if action == "Rejected":
            create_notification(
                leave["user_email"],
                "Leave Request",
                f"Your leave request was REJECTED by {role.capitalize()} ({actor_name})"
            )
        elif updates.get("finalStatus") == "Approved":
            create_notification(
                leave["user_email"],
                "Leave Request",
                "Your leave request was APPROVED by HR Manager"
            )

        return jsonify({"message": f"Leave {action} by {role}"}), 200

    except Exception as e:
        return jsonify({"message": f"Server error: {str(e)}"}), 500

# -------------------------
# Notifications
# -------------------------
def create_notification(user_email, type_, message, status="unread"):
    notifications_collection.insert_one({
        "user_email": user_email,
        "type": type_,
        "message": message,
        "status": status,
        "createdAt": datetime.utcnow().isoformat()
    })

@app.route("/notifications", methods=["GET"])
@jwt_required()
def get_notifications():
    email = get_jwt_identity()
    notifs = list(notifications_collection.find({"user_email": email}).sort("createdAt", -1))
    for n in notifs:
        n["_id"] = str(n["_id"])
    return jsonify(notifs), 200

# -------------------------
# My Leave Applications
# -------------------------
@app.route("/my-leave-applications", methods=["GET"])
@jwt_required()
def my_leave_applications():
    email = get_jwt_identity()
    leaves = list(leave_collection.find({"user_email": email}).sort("submittedAt", -1))
    for leave in leaves:
        leave["_id"] = str(leave["_id"])
    return jsonify(leaves), 200

# -------------------------
# Run Flask
# -------------------------
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)