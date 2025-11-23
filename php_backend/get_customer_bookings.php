<?php
// Endpoint to retrieve all bookings for a given customer. Accepts
// GET parameter `customer_id`. Returns a list of bookings joined
// with service and employee names for easier display in the client.

header('Content-Type: application/json');
require_once 'db.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
    exit;
}

$customerId = isset($_GET['customer_id']) ? (int)$_GET['customer_id'] : 0;
if ($customerId <= 0) {
    echo json_encode(['success' => false, 'message' => 'customer_id erforderlich']);
    exit;
}

try {
    $stmt = $pdo->prepare('SELECT b.id, b.customer_id, b.employee_id, b.service_id, b.start_datetime, b.end_datetime, b.status, s.name AS service_name, u.name AS employee_name
        FROM bookings b
        JOIN services s ON b.service_id = s.id
        JOIN users u ON b.employee_id = u.id
        WHERE b.customer_id = ?
        ORDER BY b.start_datetime');
    $stmt->execute([$customerId]);
    $bookings = $stmt->fetchAll();
    echo json_encode(['success' => true, 'bookings' => $bookings]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Serverfehler']);
}