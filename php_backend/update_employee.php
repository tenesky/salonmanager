<?php
// Endpoint to update an employee's name and email by ID.
// Expects POST parameters: id, name, email. Only updates provided fields.
// Returns JSON indicating success.

header('Content-Type: application/json');
require_once 'db.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
    exit;
}

$id = isset($_POST['id']) ? intval($_POST['id']) : 0;
$name = isset($_POST['name']) ? trim($_POST['name']) : '';
$email = isset($_POST['email']) ? trim($_POST['email']) : '';

if ($id <= 0 || $name === '' || $email === '') {
    echo json_encode(['success' => false, 'message' => 'Ungültige Parameter']);
    exit;
}

try {
    $stmt = $pdo->prepare('UPDATE users SET name = ?, email = ? WHERE id = ? AND role = ?');
    $stmt->execute([$name, $email, $id, 'employee']);
    $updated = $stmt->rowCount();
    echo json_encode(['success' => $updated > 0]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Datenbankfehler']);
}