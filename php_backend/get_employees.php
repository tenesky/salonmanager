<?php
// Endpoint to retrieve all employees (users with role 'employee').
// Returns a JSON response with a list of employees or an error.

header('Content-Type: application/json');
require_once 'db.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
    exit;
}

try {
    $stmt = $pdo->prepare('SELECT id, name, email, role FROM users WHERE role = ?');
    $stmt->execute(['employee']);
    $employees = $stmt->fetchAll();
    echo json_encode(['success' => true, 'employees' => $employees]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Datenbankfehler']);
}