<?php
// Login endpoint for the 4people app. Expects POST parameters:
// - email: the user's email address
// - password: the user's password
// - role: the role the user wants to log in as ('customer' or 'employee' or 'admin')

header('Content-Type: application/json');
require_once 'db.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
    exit;
}

$email = trim($_POST['email'] ?? '');
$password = $_POST['password'] ?? '';
$role = trim($_POST['role'] ?? '');

if ($email === '' || $password === '' || $role === '') {
    echo json_encode(['success' => false, 'message' => 'E-Mail, Passwort und Rolle sind erforderlich']);
    exit;
}

// Fetch user record
$stmt = $pdo->prepare('SELECT id, password, role FROM users WHERE email = ? LIMIT 1');
$stmt->execute([$email]);
$user = $stmt->fetch();

if (!$user || $user['role'] !== $role) {
    // Either user not found or role mismatch
    echo json_encode(['success' => false, 'message' => 'Ungültige Anmeldedaten']);
    exit;
}

// Verify password
if (!password_verify($password, $user['password'])) {
    echo json_encode(['success' => false, 'message' => 'Ungültige Anmeldedaten']);
    exit;
}

// Generate a simple token. In production you may use JWT or a proper session management.
$token = bin2hex(random_bytes(16));

// Optionally store the token in a sessions table or return it directly
echo json_encode([
    'success' => true,
    'token' => $token,
    'userId' => $user['id'],
]);