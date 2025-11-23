<?php
// Endpoint to calculate available time slots for a given service,
// employee and date. The caller must POST `service_id`,
// `employee_id` and `date` (YYYY-MM-DD). Returns an array of
// start times in HH:MM format (local time). This is a simple
// implementation that assumes fixed business hours (08:00-18:00) and
// divides the day into 15 minute increments. Existing bookings are
// excluded and the service's duration plus buffer time are
// considered when determining overlaps.

header('Content-Type: application/json');
require_once 'db.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
    exit;
}

$serviceId = isset($_POST['service_id']) ? (int)$_POST['service_id'] : 0;
$employeeId = isset($_POST['employee_id']) ? (int)$_POST['employee_id'] : 0;
$date = trim($_POST['date'] ?? '');

if ($serviceId <= 0 || $employeeId <= 0 || $date === '') {
    echo json_encode(['success' => false, 'message' => 'service_id, employee_id und date sind erforderlich']);
    exit;
}

try {
    // Retrieve service duration and buffer
    $stmt = $pdo->prepare('SELECT duration_minutes, buffer_minutes FROM services WHERE id = ?');
    $stmt->execute([$serviceId]);
    $service = $stmt->fetch();
    if (!$service) {
        echo json_encode(['success' => false, 'message' => 'Service nicht gefunden']);
        exit;
    }
    $duration = (int)$service['duration_minutes'];
    $buffer = (int)$service['buffer_minutes'];
    $slotLength = $duration + $buffer;

    // Business hours (08:00 to 18:00)
    $workStart = new DateTime($date . ' 08:00:00');
    $workEnd = new DateTime($date . ' 18:00:00');

    // Fetch existing bookings for the employee on that date
    $stmt = $pdo->prepare('SELECT start_datetime, end_datetime FROM bookings WHERE employee_id = ? AND DATE(start_datetime) = ? AND status NOT IN ("cancelled_by_customer", "cancelled_by_salon")');
    $stmt->execute([$employeeId, $date]);
    $existing = $stmt->fetchAll();

    // Build a list of intervals that block the employee
    $bookedIntervals = [];
    foreach ($existing as $row) {
        $start = new DateTime($row['start_datetime']);
        $end = new DateTime($row['end_datetime']);
        $bookedIntervals[] = [$start, $end];
    }

    $slots = [];
    $current = clone $workStart;
    while ($current < $workEnd) {
        // Compute end time for this slot
        $candidateStart = clone $current;
        $candidateEnd = clone $current;
        $candidateEnd->modify('+' . $slotLength . ' minutes');
        // Candidate must end before or exactly at workEnd
        if ($candidateEnd > $workEnd) {
            break;
        }
        // Check overlap with existing bookings
        $overlap = false;
        foreach ($bookedIntervals as $interval) {
            /** @var DateTime $bookStart */
            $bookStart = $interval[0];
            /** @var DateTime $bookEnd */
            $bookEnd = $interval[1];
            if ($candidateStart < $bookEnd && $candidateEnd > $bookStart) {
                $overlap = true;
                break;
            }
        }
        if (!$overlap) {
            // Format as HH:MM for the frontend
            $slots[] = $candidateStart->format('H:i');
        }
        // Move to next 15 minute increment
        $current->modify('+15 minutes');
    }

    echo json_encode(['success' => true, 'slots' => $slots]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Serverfehler']);
}