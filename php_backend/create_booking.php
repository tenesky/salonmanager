<?php
// Endpoint to create a new appointment booking. Expects POST
// parameters: customer_id, employee_id, service_id, start_datetime,
// end_datetime (ISO 8601 or YYYY-MM-DD HH:MM:SS). Checks for
// overlaps and inserts the booking if possible.

header('Content-Type: application/json');
require_once 'db.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
    exit;
}

$customerId = isset($_POST['customer_id']) ? (int)$_POST['customer_id'] : 0;
$employeeId = isset($_POST['employee_id']) ? (int)$_POST['employee_id'] : 0;
$serviceId = isset($_POST['service_id']) ? (int)$_POST['service_id'] : 0;
$startDatetime = trim($_POST['start_datetime'] ?? '');
$endDatetime = trim($_POST['end_datetime'] ?? '');

if ($customerId <= 0 || $employeeId <= 0 || $serviceId <= 0 || $startDatetime === '' || $endDatetime === '') {
    echo json_encode(['success' => false, 'message' => 'Alle Parameter sind erforderlich']);
    exit;
}

try {
    // Convert to DateTime for comparison
    $start = new DateTime($startDatetime);
    $end = new DateTime($endDatetime);
    if ($end <= $start) {
        echo json_encode(['success' => false, 'message' => 'Ungültiges Zeitintervall']);
        exit;
    }

    // Check for overlapping bookings for this employee
    $stmt = $pdo->prepare('SELECT id FROM bookings WHERE employee_id = ? AND ((start_datetime < ?) AND (end_datetime > ?)) AND status NOT IN ("cancelled_by_customer", "cancelled_by_salon")');
    $stmt->execute([$employeeId, $end->format('Y-m-d H:i:s'), $start->format('Y-m-d H:i:s')]);
    $conflict = $stmt->fetch();
    if ($conflict) {
        echo json_encode(['success' => false, 'message' => 'Zeitfenster ist nicht verfügbar']);
        exit;
    }

    // Insert booking
    $stmt = $pdo->prepare('INSERT INTO bookings (customer_id, employee_id, service_id, start_datetime, end_datetime, status) VALUES (?, ?, ?, ?, ?, ?)');
    $status = 'confirmed';
    $stmt->execute([
        $customerId,
        $employeeId,
        $serviceId,
        $start->format('Y-m-d H:i:s'),
        $end->format('Y-m-d H:i:s'),
        $status,
    ]);
    $bookingId = $pdo->lastInsertId();
    echo json_encode(['success' => true, 'booking_id' => $bookingId]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Serverfehler']);
}