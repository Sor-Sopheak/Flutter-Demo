import 'package:flutter/material.dart';
import 'package:flutter_demo/constants/color_constants.dart';
import 'package:flutter_week_view/flutter_week_view.dart';
import 'package:intl/intl.dart';

// Extension to help with time-only operations (not part of the package)
extension on DateTime {
  DateTime get withoutSpecificTime => DateTime(year, month, day);
}

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime? dragStart;
  DateTime? dragEnd;
  List<FlutterWeekViewEvent> _events = []; // Temporary selection visualization
  List<FlutterWeekViewEvent> _permanentEvents = [];
  List<FlutterWeekViewEvent> _blockEvents = [];
  List<String> _filterOptions = [
    'Internal',
    'External',
  ]; //A = internal, B = external
  String _selectedFilter = 'Internal';

  final double _hourRowHeight = 45.0;
  final GlobalKey _dayViewKey =
      GlobalKey(); // Key to find the widget's position

  DateTime _currentDate = DateTime.now().withoutSpecificTime;
  static const int _startHour = 6;
  static const int _endHour = 22;
  static const int _slotMinutes = 30; // NEW: Slot granularity

  @override
  void initState() {
    super.initState();
    DateTime now = DateTime.now().withoutSpecificTime;
    _permanentEvents.add(
      FlutterWeekViewEvent(
        title: 'Busy Slot (8:30 - 9:30)',
        description: 'Internal',
        start: now.copyWith(hour: 8, minute: 30),
        end: now.copyWith(hour: 9, minute: 30),
      ),
    );
    _permanentEvents.add(
      FlutterWeekViewEvent(
        title: 'Lunch Break (12:00 - 1:00)',
        description: 'External',
        start: now.copyWith(hour: 12, minute: 0),
        end: now.copyWith(hour: 13, minute: 0),
      ),
    );

    _generateBlockEvents(_currentDate);
  }

  String _formatTime(DateTime dt) {
    return '${dt.month}/${dt.day}/${dt.year} ${dt.hour % 12}:${dt.minute.toString().padLeft(2, '0')} ${dt.hour >= 12 ? 'PM' : 'AM'}';
  }

  //for column hour
  String _formatHourColumnTime(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return '\n${DateFormat('h:mm a').format(dt)}';
  }

  // --- 2. Coordinate Conversion Logic ---
  DateTime _offsetToTime(double yOffset) {
    double totalMinutesFromStartHour = (yOffset / _hourRowHeight) * 60;

    // Total minutes from midnight (00:00)
    int totalMinutesFromMidnight =
        (_startHour * 60) + totalMinutesFromStartHour.round();

    // Snapping to the nearest _slotMinutes (30 minutes)
    int snappedMinutesFromMidnight =
        (totalMinutesFromMidnight / _slotMinutes).round() * _slotMinutes;

    DateTime calculatedTime = _currentDate.add(
      Duration(minutes: snappedMinutesFromMidnight),
    );

    // Define max time for the view (22:00)
    DateTime maxTime = _currentDate.copyWith(
      hour: _endHour,
      minute: 0,
      second: 0,
      millisecond: 0,
      microsecond: 0,
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

  void _handleDragEnd(DragEndDetails details) {
    if (dragStart != null && dragEnd != null) {
      DateTime selection1 = dragStart!;
      DateTime selection2 = dragEnd!;

      DateTime start =
          selection1.isBefore(selection2) ? selection1 : selection2;
      DateTime end = selection2.isAfter(selection1) ? selection2 : selection1;

      if (end.difference(start).inMinutes < _slotMinutes) {
        end = start.add(const Duration(minutes: _slotMinutes));
      }

      // 1. Conflict Check (Checks against all existing immovable slots)
      if (_isConflict(start, end)) {
        setState(() {
          dragStart = null;
          dragEnd = null;
          _events = [];
        });
        // _showConflictMessage(context, start, end);
        return;
      }

      // --- 2. Event Confirmation and Intelligent Addition ---
      final newEventType = _selectedFilter;

      FlutterWeekViewEvent newPermanentEvent = FlutterWeekViewEvent(
        title: 'New ${newEventType} Slot',
        description: newEventType,
        start: start,
        end: end,
      );

      setState(() {
        // Add the new event to the permanent list
        _permanentEvents.add(newPermanentEvent);

        // Clear the temporary drag visualization
        dragStart = null;
        dragEnd = null;
        _events = [];

        // Trigger Block Generation: This ensures the new event's block
        // boundaries are calculated and displayed immediately.
        _generateBlockEvents(_currentDate);
      });
    }
  }

  bool _isConflict(DateTime newStart, DateTime newEnd) {
    final immovableEvents = [..._permanentEvents, ..._blockEvents];

    for (final event in immovableEvents) {
      DateTime existingStart = event.start;
      DateTime existingEnd = event.end;

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
  void _showConflictMessage(
    BuildContext context,
    DateTime start,
    DateTime end,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          backgroundColor: Colors.red.shade50,
          title: const Text(
            'Slot Unavailable 🚫',
            style: TextStyle(color: Colors.red),
          ),
          content: Text(
            'The time slot from ${_formatTime(start)} to ${_formatTime(end)} conflicts with an existing event. Please choose an empty time slot.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'OK',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
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

  String _getMonthName(int month) {
    const names = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return names[month];
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

  Widget _buildDropdownFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Theme.of(context).primaryColor, width: 1.0),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedFilter,
          icon: Icon(
            Icons.arrow_drop_down,
            color: Theme.of(context).primaryColor,
          ),
          // Style the text of the selected item
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),

          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedFilter = newValue;
                _generateBlockEvents(_currentDate);
              });
            }
          },
          items:
              _filterOptions.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
        ),
      ),
    );
  }

  Widget _buildCalendarHeader() {
    DateTime startOfWeek = _currentDate.subtract(
      Duration(days: _currentDate.weekday - 1),
    );
    DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));

    String headerText;
    if (startOfWeek.month == endOfWeek.month) {
      headerText = '${_getMonthName(startOfWeek.month)} ${startOfWeek.year}';
    } else {
      headerText =
          '${_getMonthName(startOfWeek.month)} ${endOfWeek.day}, ${endOfWeek.year}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
      color: Color(whiteColor),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Color(blueColor),
              size: 16,
            ),
            onPressed: _goToPreviousWeek,
          ),
          GestureDetector(
            onTap: () => _selectDate(context),
            child: Text(
              headerText,
              style: const TextStyle(
                color: Color(blackColor),
                fontWeight: FontWeight.w500,
                fontSize: 20,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.arrow_forward_ios,
              color: Color(blueColor),
              size: 16,
            ),
            onPressed: _goToNextWeek,
          ),
        ],
      ),
    );
  }

  // --- NEW: Weekday Selector Header ---
  Widget _buildDayOfWeekSelector() {
    DateTime startOfWeek = _currentDate.subtract(
      Duration(days: _currentDate.weekday - 1),
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      color: Color(whiteColor),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(7, (index) {
          DateTime day = startOfWeek.add(Duration(days: index));
          bool isSelected = day.isAtSameMomentAs(_currentDate);

          Color dayTextColor = Color(primaryTextColor); // Default for weekdays
          if (day.weekday == DateTime.saturday ||
              day.weekday == DateTime.sunday) {
            dayTextColor = Colors.red; // Red for weekends
          }
          if (isSelected) {
            dayTextColor = Color(whiteColor);
          }

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _currentDate = day.withoutSpecificTime;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isSelected ? Color(blueColor) : Colors.transparent,
                  shape: BoxShape.rectangle,
                  borderRadius:
                      isSelected
                          ? BorderRadius.circular(4)
                          : BorderRadius.circular(0),
                ),
                child: Column(
                  children: [
                    // Weekday Text (Mon, Tue, etc.)
                    Text(
                      DateFormat(
                        'E',
                      ).format(day), // 'E' gives short day name (Mon)
                      style: TextStyle(
                        color: dayTextColor,
                        fontWeight: FontWeight.w400,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      day.day.toString(),
                      style: TextStyle(
                        color: dayTextColor,
                        fontWeight:
                            isSelected ? FontWeight.w500 : FontWeight.normal,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // --- 8. Custom Event Builder ---
  Widget _customEventBuilder(
    FlutterWeekViewEvent event,
    double top,
    double height,
  ) {
    if (event.description == 'Blocked') {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade400.withOpacity(0.6), // Grey color for block
          borderRadius: BorderRadius.circular(4.0),
          border: Border.all(color: Colors.grey.shade600, width: 1.0),
        ),
        padding: const EdgeInsets.all(4.0),
        child: Center(
          child: Text(
            'BLOCKED', // Display text for block slot
            style: TextStyle(color: Colors.grey.shade700, fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    Color color;
    Color borderColor;
    String type =
        event
            .description; // Get the type ('Internal', 'External', or 'Temporary')

    if (type == 'Temporary') {
      color = Colors.red.withOpacity(0.4);
      borderColor = Colors.red.shade900;
    } else if (type == 'Internal') {
      color = Colors.blue.withOpacity(0.6); // Internal (A) color
      borderColor = Colors.blue.shade900;
    } else if (type == 'External') {
      color = Colors.green.withOpacity(0.6); // External (B) color
      borderColor = Colors.green.shade900;
    } else {
      // Default/Fallback
      color = Colors.purple.withOpacity(0.6);
      borderColor = Colors.purple.shade900;
    }

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

  void _generateBlockEvents(DateTime date) {
    final blockDuration = const Duration(minutes: 30);
    final currentFilter = _selectedFilter;
    List<FlutterWeekViewEvent> newBlocks = [];

    for (final event in _permanentEvents) {
      if (!event.start.withoutSpecificTime.isAtSameMomentAs(date)) {
        continue; // Skip events not on the current day
      }

      final existingType = event.description;
      DateTime existingStart = event.start;
      DateTime existingEnd = event.end;

      // --- CASE 1: Current Filter is 'Internal' (A) ---
      if (currentFilter == 'Internal') {
        if (existingType == 'External') {
          newBlocks.add(
            FlutterWeekViewEvent(
              title: 'Blocked (Internal)',
              description: 'Blocked',
              start: existingStart.subtract(blockDuration),
              end: existingStart,
            ),
          );
        }
      }

      // --- CASE 2: Current Filter is 'External' (B) ---
      if (currentFilter == 'External') {
        if (existingType == 'Internal') {
          newBlocks.add(
            FlutterWeekViewEvent(
              title: 'Blocked (External)',
              description: 'Blocked',
              start: existingEnd,
              end: existingEnd.add(blockDuration),
            ),
          );
          // newBlocks.add(
          //   FlutterWeekViewEvent(
          //     title: 'Blocked (External)',
          //     description: 'Blocked',
          //     start: existingStart.subtract(blockDuration),
          //     end: existingStart,
          //   ),
          // );
          // newBlocks.add(
          //   FlutterWeekViewEvent(
          //     title: 'Blocked (External)',
          //     description: 'Blocked',
          //     start: existingEnd,
          //     end: existingEnd.add(blockDuration),
          //   ),
          // );
        }
        // 💡 NEW Rule 2B: Existing External (B) -> Block before AND after
        else if (existingType == 'External') {
          newBlocks.add(
            FlutterWeekViewEvent(
              title: 'Blocked (External)',
              description: 'Blocked',
              start: existingStart.subtract(blockDuration),
              end: existingStart,
            ),
          );
          newBlocks.add(
            FlutterWeekViewEvent(
              title: 'Blocked (External)',
              description: 'Blocked',
              start: existingEnd,
              end: existingEnd.add(blockDuration),
            ),
          );
          // newBlocks.add(
          //   FlutterWeekViewEvent(
          //     title: 'Blocked (External)',
          //     description: 'Blocked',
          //     start: existingStart.subtract(blockDuration),
          //     end: existingStart,
          //   ),
          // );
          // newBlocks.add(
          //   FlutterWeekViewEvent(
          //     title: 'Blocked (External)',
          //     description: 'Blocked',
          //     start: existingEnd,
          //     end: existingEnd.add(blockDuration),
          //   ),
          // );
        }
      }
    }

    // Update state with new blocks
    setState(() {
      _blockEvents = newBlocks;
    });
  }

  Widget _buildRoomInfoSector() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Digital meeting room A1 Building A 1st Floor',
            style: TextStyle(
              color: Color(blackColor),
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          Row(
            children: [
              Icon(
                Icons.people_alt_outlined,
                color: Color(iconGreyColor),
                size: 18,
              ),
              SizedBox(width: 4),
              Text(
                'Contain 10 people',
                style: TextStyle(
                  color: Color(primaryTextColor),
                  fontWeight: FontWeight.w400,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: const Text("Room information (flutter_week_view)")),
      body: Container(
        color: Color(whiteColor),
        child: Column(
          children: [
            _buildDropdownFilter(),
            _buildCalendarHeader(),
            _buildDayOfWeekSelector(),
            _buildRoomInfoSector(),
            Divider(color: Color(0xFFE5E5E5), thickness: 1),
            Expanded(
              child: GestureDetector(
                key: _dayViewKey,
                behavior: HitTestBehavior.opaque,
                onVerticalDragStart: _handleDragStart,
                onVerticalDragUpdate: _handleDragUpdate,
                onVerticalDragEnd: _handleDragEnd,
                child: DayView(
                  date: _currentDate,
                  events: [..._permanentEvents, ..._blockEvents, ..._events],
                  eventWidgetBuilder: _customEventBuilder,
                  initialTime: const TimeOfDay(hour: _startHour, minute: 0),
                  minimumTime: const TimeOfDay(hour: 5, minute: 50),
                  maximumTime: const TimeOfDay(hour: _endHour, minute: 0),
                  userZoomable: false,
                  inScrollableWidget: false, //true = drag not work
                  style: DayViewStyle(
                    hourRowHeight: _hourRowHeight,
                    headerSize: 0.0,
                    backgroundColor: Color(whiteColor),
                    backgroundRulesColor: Color(0XFFD8E3FF),
                    currentTimeRuleColor: Colors.transparent,
                  ),
                  hourColumnStyle: HourColumnStyle(
                    width: 80,
                    textAlignment: Alignment.center,
                    textStyle: TextStyle(
                      color: Color(primaryTextColor),
                      fontSize: 12,
                    ),
                    timeFormatter: _formatHourColumnTime,
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(color: Color(0XFFD8E3FF), width: 1),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
