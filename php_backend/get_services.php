<?php
// Endpoint to retrieve all services. Returns a JSON array of service
// records including id, name, duration_minutes, price and buffer_minutes.

header('Content-Type: application/json');
require_once 'db.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
    exit;
}

try {
    $stmt = $pdo->query('SELECT id, name, duration_minutes, price, buffer_minutes FROM services');
    $services = $stmt->fetchAll();
    echo json_encode(['success' => true, 'services' => $services]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Datenbankfehler']);
}