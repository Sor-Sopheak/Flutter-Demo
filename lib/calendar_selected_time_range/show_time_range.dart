import 'package:flutter/material.dart';
import 'package:flutter_week_view/flutter_week_view.dart';
import 'package:intl/intl.dart';

// --- 1. CalendarPage Widget ---
class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  // State variables for tracking the selection
  DateTime? dragStart;
  DateTime? dragEnd;
  List<FlutterWeekViewEvent> _events = []; // Temporary selection visualization
  List<FlutterWeekViewEvent> _permanentEvents = []; // NEW: List to store confirmed, permanent events

  // Configuration Constants
  final double _hourRowHeight = 60.0;
  final GlobalKey _dayViewKey = GlobalKey(); // Key to find the widget's position
  // final DateTime _targetDate = DateTime.now().withoutSpecificTime;

  // State variable for the currently displayed date (needed for navigation)
  DateTime _currentDate =
      DateTime.now()
          .withoutSpecificTime; // Use withoutSpecificTime from extension
  static const int _startHour = 6;
  static const int _endHour = 22;
  static const int _slotMinutes = 30;   // NEW: Slot granularity

  @override
  void initState() {
    super.initState();
    // Add a couple of initial events for testing conflict detection
    DateTime now = DateTime.now().withoutSpecificTime;
    _permanentEvents.add(FlutterWeekViewEvent(
      title: 'Busy Slot (8:30 - 9:30)',
      description: 'Pre-existing Meeting',
      start: now.copyWith(hour: 8, minute: 30),
      end: now.copyWith(hour: 9, minute: 30),
    ));
    _permanentEvents.add(FlutterWeekViewEvent(
      title: 'Lunch Break (12:00 - 1:00)',
      description: 'Scheduled Break',
      start: now.copyWith(hour: 12, minute: 0),
      end: now.copyWith(hour: 13, minute: 0),
    ));
  }

  String _formatTime(DateTime dt) {
    // Simple format: 11/18/2025 09:30 AM (Customize as needed)
    return '${dt.month}/${dt.day}/${dt.year} ${dt.hour % 12}:${dt.minute.toString().padLeft(2, '0')} ${dt.hour >= 12 ? 'PM' : 'AM'}';
  }

  // --- 2. Coordinate Conversion Logic ---
  // This is the core manual logic for converting screen pixels (yOffset) to time.
  DateTime _offsetToTime(double yOffset) {
    double totalMinutesFromStartHour = (yOffset / _hourRowHeight) * 60;
    
    // Total minutes from midnight (00:00)
    int totalMinutesFromMidnight = (_startHour * 60) + totalMinutesFromStartHour.round();

    // Snapping to the nearest _slotMinutes (30 minutes)
    int snappedMinutesFromMidnight = (totalMinutesFromMidnight / _slotMinutes).round() * _slotMinutes;

    DateTime calculatedTime = _currentDate.add(Duration(minutes: snappedMinutesFromMidnight));
    
    // Define max time for the view (22:00)
    DateTime maxTime = _currentDate.copyWith(
        hour: _endHour, 
        minute: 0, 
        second: 0, 
        millisecond: 0, 
        microsecond: 0
    );
    
    // If the calculation exceeds the max time, snap to max time
    if (calculatedTime.isAfter(maxTime)) {
        return maxTime;
    }
    
    return calculatedTime.copyWith(second: 0, millisecond: 0, microsecond: 0);
  }

  // --- 3. Drag Gesture Handlers ---
  void _handleDragUpdate(DragUpdateDetails details) {
    final RenderBox? renderBox =
        _dayViewKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final localOffset = renderBox.globalToLocal(details.globalPosition);

    setState(() {
      dragEnd = _offsetToTime(localOffset.dy);
      _updateSelectionEvent();
    });
  }

  void _handleDragStart(DragStartDetails details) {
    final RenderBox? renderBox =
        _dayViewKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final localOffset = renderBox.globalToLocal(details.globalPosition);

    setState(() {
      dragStart = _offsetToTime(localOffset.dy);
      dragEnd = dragStart;
      _updateSelectionEvent();
    });
  }

  // The DayView's Time Range is captured here and the dialog is shown.
  void _handleDragEnd(DragEndDetails details) {
    if (dragStart != null && dragEnd != null) {
      DateTime selection1 = dragStart!;
      DateTime selection2 = dragEnd!;

      // FIX: Determine the true start and end using isBefore/isAfter to avoid the 'Never' type error.
      DateTime start =
          selection1.isBefore(selection2) ? selection1 : selection2;
      DateTime end = selection2.isAfter(selection1) ? selection2 : selection1;

      // Minimum duration for a valid selection is one slot (30 minutes)
      if (end.difference(start).inMinutes < _slotMinutes) {
         end = start.add(const Duration(minutes: _slotMinutes));
      }

      // Check for conflict
      if (_isConflict(start, end)) {
        setState(() {
          dragStart = null;
          dragEnd = null;
          _events = [];
        });
        _showConflictMessage(context, start, end);
        return; 
      }

      // Trigger the modal popup with the final range
      _showSelectionDetailsDialog(start, end);
    }
  }

  // --- 4. Conflict Detection Logic (NEW) ---
  bool _isConflict(DateTime newStart, DateTime newEnd) {
    // Ensure the new time range is valid
    if (newStart.isAtSameMomentAs(newEnd)) {
      return false; // A zero-length slot can't conflict (although logic prevents this)
    }

    for (final event in _permanentEvents) {
      final existingStart = event.start;
      final existingEnd = event.end;

      // Check for overlap: 
      // 1. New event starts strictly before existing event ends AND 
      // 2. New event ends strictly after existing event starts.
      // Events touching (e.g., 7:00-7:30 and 7:30-8:00) are allowed.
      if (newStart.isBefore(existingEnd) && newEnd.isAfter(existingStart)) {
        return true; 
      }
    }
    return false;
  }

  // --- 5. Event Update Logic ---
  void _updateSelectionEvent() {
    if (dragStart != null && dragEnd != null) {
      DateTime selection1 = dragStart!;
      DateTime selection2 = dragEnd!;

      // FIX 1: Use isBefore/isAfter instead of min/max to resolve the 'Never' type error.
      // Ensure 'start' is always the earlier time and 'end' is always the later time.
      DateTime start =
          selection1.isBefore(selection2) ? selection1 : selection2;
      DateTime end = selection2.isAfter(selection1) ? selection2 : selection1;

      // Give the event a minimum duration
      if (end.isAtSameMomentAs(start)) {
        end = end.add(const Duration(minutes: 5));
      }

      _events = [
        FlutterWeekViewEvent(
          title: "New Time Slot",
          description: "Drag Selection",
          start: start,
          end: end,
        ),
      ];
    } else {
      _events = [];
    }
  }

  // --- 6. Modal Dialogs ---
  void _showConflictMessage(BuildContext context, DateTime start, DateTime end) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
          backgroundColor: Colors.red.shade50,
          title: const Text('Slot Unavailable 🚫', style: TextStyle(color: Colors.red)),
          content: Text(
            'The time slot from ${_formatTime(start)} to ${_formatTime(end)} conflicts with an existing event. Please choose an empty time slot.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showSelectionDetailsDialog(DateTime start, DateTime end) {
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('✅ Name Your Event'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Input Field for Event Name (NEW)
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Event Name',
                  hintText: 'e.g., Team Sync Meeting',
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Selected Date: ${_formatTime(start).split(' ')[0]}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Start Time: ${_formatTime(start).split(' ')[1]} ${_formatTime(start).split(' ')[2]}',
              ),
              Text(
                'End Time: ${_formatTime(end).split(' ')[1]} ${_formatTime(end).split(' ')[2]}',
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
                // Clear the temporary visual selection
                setState(() {
                  dragStart = null;
                  dragEnd = null;
                  _events = [];
                });
              },
            ),
            ElevatedButton(
              child: const Text('Save'),
              onPressed: () {
                final eventName =
                    nameController.text.isEmpty
                        ? 'Untitled Event'
                        : nameController.text;

                final newEvent = FlutterWeekViewEvent(
                  title: eventName,
                  description: 'Saved Event',
                  start: start,
                  end: end,
                );

                // SAVE LOGIC: Persist the new event
                setState(() {
                  _permanentEvents.add(newEvent);

                  // Clear the temporary visual selection
                  dragStart = null;
                  dragEnd = null;
                  _events = [];
                });

                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    ).then((_) {
      // Ensure the controller is disposed after the dialog closes
      nameController.dispose();
    });
  }

  // --- 6. Navigation and Header Functions ---
  void _goToPreviousWeek() {
    setState(() {
      _currentDate = _currentDate.subtract(const Duration(days: 7));
    });
  }

  void _goToNextWeek() {
    setState(() {
      _currentDate = _currentDate.add(const Duration(days: 7));
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _currentDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _currentDate) {
      setState(() {
        _currentDate = picked.withoutSpecificTime;
      });
    }
  }

  Widget _buildCalendarHeader() {
    DateTime startOfWeek = _currentDate.subtract(Duration(days: _currentDate.weekday - 1));
    DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));
    
    String headerText;
    if (startOfWeek.month == endOfWeek.month) {
        headerText = '${_getMonthName(startOfWeek.month)} ${startOfWeek.day} - ${endOfWeek.day}, ${startOfWeek.year}';
    } else {
        headerText = '${_getMonthName(startOfWeek.month)} ${startOfWeek.day} - ${_getMonthName(endOfWeek.month)} ${endOfWeek.day}, ${endOfWeek.year}';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
      color: Theme.of(context).primaryColor, // Use primary color for main header
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 16),
            onPressed: _goToPreviousWeek,
          ),
          GestureDetector(
            onTap: () => _selectDate(context),
            child: Text(
              headerText,
              style: const TextStyle(
                color: Colors.white, 
                fontWeight: FontWeight.bold, 
                fontSize: 18
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
            onPressed: _goToNextWeek,
          ),
        ],
      ),
    );
  }

  // --- NEW: Weekday Selector Header ---
  Widget _buildDayOfWeekSelector() {
    // Find the Monday of the current week (ISO 8601 starts with Monday = 1)
    DateTime startOfWeek = _currentDate.subtract(Duration(days: _currentDate.weekday - 1));
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      color: Theme.of(context).primaryColor.withOpacity(0.9),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(7, (index) {
          DateTime day = startOfWeek.add(Duration(days: index));
          bool isSelected = day.isAtSameMomentAs(_currentDate);
          
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _currentDate = day;
                });
              },
              child: Column(
                children: [
                  // Weekday Text (Mon, Tue, etc.)
                  Text(
                    DateFormat('E').format(day), // 'E' gives short day name (Mon)
                    style: TextStyle(
                      color: isSelected ? Colors.yellowAccent : Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Day Number Circle
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.transparent,
                      shape: BoxShape.circle,
                      border: isSelected 
                          ? Border.all(color: Colors.transparent)
                          : Border.all(color: Colors.white38),
                    ),
                    child: Text(
                      day.day.toString(),
                      style: TextStyle(
                        color: isSelected ? Theme.of(context).primaryColor : Colors.white,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
  
  String _getMonthName(int month) {
    const names = [
      '', 'January', 'February', 'March', 'April', 'May', 'June', 
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return names[month];
  }

  // --- 8. Custom Event Builder ---
  Widget _customEventBuilder(FlutterWeekViewEvent event, double top, double height) {
    Color color = event.description == 'Temporary' 
        ? Colors.red.withOpacity(0.4) 
        : Colors.blue.withOpacity(0.6);
        
    Color borderColor = event.description == 'Temporary' ? Colors.red.shade900 : Colors.blue.shade900;

    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4.0),
        border: Border.all(color: borderColor, width: 2.0),
      ),
      padding: const EdgeInsets.all(4.0),
      child: Center(
        child: Text(
          event.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filter permanent events to only show those for the currently selected day
    List<FlutterWeekViewEvent> filteredEvents = _permanentEvents.where((event) {
      return event.start.withoutSpecificTime.isAtSameMomentAs(_currentDate);
    }).toList();

    const TimeOfDay _startTime = TimeOfDay(hour: 6, minute: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Drag Time Selection (flutter_week_view)"),
      ),
      body: Column(
        children: [
          // 1. Calendar Navigation Header (Month/Week Navigation)
          _buildCalendarHeader(), 
          
          // 2. Day of Week Selector (Mon - Sun buttons)
          _buildDayOfWeekSelector(), 
          
          // 3. Day View (Expanded to take remaining space)
          Expanded(
            child: GestureDetector(
              key: _dayViewKey, // The key is critical for coordinate calculation
              behavior: HitTestBehavior.opaque,
              onVerticalDragStart: _handleDragStart,
              onVerticalDragUpdate: _handleDragUpdate,
              onVerticalDragEnd: _handleDragEnd,
              child: DayView(
                // Use the new state variable for the date
                date: _currentDate,
                events: [..._events, ...filteredEvents],
            
                // **CRITICAL FIX:** Replaced eventTextBuilder with the correct property:
                eventWidgetBuilder: _customEventBuilder,
            
                // --- FIX 1: Time Range and Initial Position ---
                initialTime: const TimeOfDay(hour: _startHour, minute: 0), 
                
                // ⬇️ CRITICAL FIX: Set minimumTime to 5:30 AM ⬇️
                // This forces the 6:00 AM hour label to display below the top boundary.
                minimumTime: const TimeOfDay(hour: 5, minute: 50), 
                
                // The maximum time remains correct for the end boundary
                maximumTime: const TimeOfDay(hour: _endHour, minute: 0),
                // --- FIX 2: Disable Zoom ---
                userZoomable: false,

                // dayBarStyle: const DayBarStyle(
                //   color: Colors.transparent, // Make background transparent
                //   decoration: BoxDecoration()
                // ),
            
                // 2. Set the row height via DayViewStyle
                style: DayViewStyle(
                  hourRowHeight: _hourRowHeight, // <--- FIXED HOUR ROW HEIGHT
                  headerSize: 0.0,
                  // minuteSplit: _slotMinutes, 
                  // backgroundSpanDecoration: BoxDecoration(
                  //   color: Colors.grey.shade100,
                  // )
                ),
                
                // 3. Set the column style (kept separate for completeness)
                hourColumnStyle: HourColumnStyle(
                  width: 60,
                  textStyle: TextStyle(color: Theme.of(context).primaryColor, fontSize: 10),
                  // separatorColor: Theme.of(context).primaryColor,
                  // separatorThickness: 1.0,
                ),
            
                // CRITICAL: Disable internal scrolling/interaction
                inScrollableWidget: false,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Extension to help with time-only operations (not part of the package)
extension on DateTime {
  DateTime get withoutSpecificTime => DateTime(year, month, day);
}
