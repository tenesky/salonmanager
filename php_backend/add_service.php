<?php
// Endpoint to add a new service. Accepts POST parameters:
// name, duration_minutes, price (optional), buffer_minutes (optional).
// Returns JSON indicating success and the inserted service ID.

header('Content-Type: application/json');
require_once 'db.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
    exit;
}

$name = isset($_POST['name']) ? trim($_POST['name']) : '';
$duration = isset($_POST['duration_minutes']) ? intval($_POST['duration_minutes']) : 0;
$price = isset($_POST['price']) ? floatval($_POST['price']) : 0.0;
$buffer = isset($_POST['buffer_minutes']) ? intval($_POST['buffer_minutes']) : 0;

if ($name === '' || $duration <= 0) {
    echo json_encode(['success' => false, 'message' => 'Ungültige Eingabedaten']);
    exit;
}

try {
    $stmt = $pdo->prepare('INSERT INTO services (name, duration_minutes, price, buffer_minutes) VALUES (?, ?, ?, ?)');
    $stmt->execute([$name, $duration, $price, $buffer]);
    $id = $pdo->lastInsertId();
    echo json_encode(['success' => true, 'id' => $id]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Datenbankfehler']);
}