<?php
// Endpoint to update an existing service. Accepts POST parameters:
// id (service ID), name, duration_minutes, price, buffer_minutes.
// Only updates provided fields. Returns JSON indicating success.

header('Content-Type: application/json');
require_once 'db.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
    exit;
}

$id = isset($_POST['id']) ? intval($_POST['id']) : 0;
$name = isset($_POST['name']) ? trim($_POST['name']) : null;
$duration = isset($_POST['duration_minutes']) ? intval($_POST['duration_minutes']) : null;
$price = isset($_POST['price']) ? floatval($_POST['price']) : null;
$buffer = isset($_POST['buffer_minutes']) ? intval($_POST['buffer_minutes']) : null;

if ($id <= 0) {
    echo json_encode(['success' => false, 'message' => 'Ungültige Service-ID']);
    exit;
}

// Build update query dynamically to allow partial updates
$fields = [];
$params = [];
if ($name !== null && $name !== '') {
    $fields[] = 'name = ?';
    $params[] = $name;
}
if ($duration !== null && $duration > 0) {
    $fields[] = 'duration_minutes = ?';
    $params[] = $duration;
}
if ($price !== null && $price >= 0) {
    $fields[] = 'price = ?';
    $params[] = $price;
}
if ($buffer !== null && $buffer >= 0) {
    $fields[] = 'buffer_minutes = ?';
    $params[] = $buffer;
}

if (empty($fields)) {
    echo json_encode(['success' => false, 'message' => 'Keine Felder zum Aktualisieren']);
    exit;
}

$params[] = $id;

try {
    $sql = 'UPDATE services SET ' . implode(', ', $fields) . ' WHERE id = ?';
    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    $updated = $stmt->rowCount();
    echo json_encode(['success' => $updated > 0]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Datenbankfehler']);
}