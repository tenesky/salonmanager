<?php
// Registration endpoint for the 4people app. Expects POST parameters:
// - name: the user's full name
// - email: the user's email address
// - password: the user's password (plain text, will be hashed)
// - role: the desired role ('customer' or 'employee' or 'admin')

header('Content-Type: application/json');
require_once 'db.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
    exit;
}

$name = trim($_POST['name'] ?? '');
$email = trim($_POST['email'] ?? '');
$password = $_POST['password'] ?? '';
$role = trim($_POST['role'] ?? 'customer');

if ($name === '' || $email === '' || $password === '' || $role === '') {
    echo json_encode(['success' => false, 'message' => 'Name, E-Mail, Passwort und Rolle sind erforderlich']);
    exit;
}

// Check if email already exists
$stmt = $pdo->prepare('SELECT id FROM users WHERE email = ? LIMIT 1');
$stmt->execute([$email]);
$existing = $stmt->fetch();
if ($existing) {
    echo json_encode(['success' => false, 'message' => 'E-Mail ist bereits registriert']);
    exit;
}

// Hash password
$hashedPassword = password_hash($password, PASSWORD_DEFAULT);

// Insert new user
$stmt = $pdo->prepare('INSERT INTO users (name, email, password, role) VALUES (?, ?, ?, ?)');
try {
    $stmt->execute([$name, $email, $hashedPassword, $role]);
    echo json_encode(['success' => true, 'message' => 'Registrierung erfolgreich']);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Datenbankfehler']);
}