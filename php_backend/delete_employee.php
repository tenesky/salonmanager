<?php
// Endpoint to delete an employee (user with role 'employee') by ID.
// Expects POST parameter 'id'. Returns JSON indicating success.

header('Content-Type: application/json');
require_once 'db.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
    exit;
}

$id = isset($_POST['id']) ? intval($_POST['id']) : 0;
if ($id <= 0) {
    echo json_encode(['success' => false, 'message' => 'Ungültige ID']);
    exit;
}

try {
    // Ensure we only delete employees
    $stmt = $pdo->prepare('DELETE FROM users WHERE id = ? AND role = ?');
    $stmt->execute([$id, 'employee']);
    $deleted = $stmt->rowCount();
    echo json_encode(['success' => $deleted > 0]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Datenbankfehler']);
}