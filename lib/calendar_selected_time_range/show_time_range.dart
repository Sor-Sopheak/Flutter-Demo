import 'package:flutter/material.dart';
import 'package:flutter_demo/constants/color_constants.dart';
import 'package:flutter_demo/constants/navbar.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class ShowTimeRange extends StatefulWidget {
  const ShowTimeRange({super.key});

  @override
  State<ShowTimeRange> createState() => _ShowTimeRangeState();
}

class _ShowTimeRangeState extends State<ShowTimeRange> {
  final CalendarController _calendarController = CalendarController();
  DateTime? start;
  DateTime? end;

  @override
  void initState() {
    super.initState();
    _setupKhmerLocale();
  }

  void _setupKhmerLocale() {
    Intl.defaultLocale = "km";
    _calendarController.view = CalendarView.week;
  }

  String _getKhmerMonthYear(DateTime date) {
    final formatter = DateFormat("MMMM yyyy", "km");
    return formatter.format(date);
  }

  void _goToPreviousWeek() {
    setState(() {
      _calendarController.displayDate = _calendarController.displayDate!
          .subtract(const Duration(days: 7));
    });
  }

  void _goToNextWeek() {
    setState(() {
      _calendarController.displayDate = _calendarController.displayDate!.add(
        const Duration(days: 7),
      );
    });
  }

  void _openSelectedRangeModal() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final formatter = DateFormat("EEEE dd MMMM yyyy HH:mm", "km");
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "ពេលវេលាដែលបានជ្រើស",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text("ចាប់ពី: ${formatter.format(start!)}"),
              Text("ដល់: ${formatter.format(end!)}"),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("យល់ព្រម"),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Navbar(),
      body: Container(
        color: Color(bgColor),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _goToPreviousWeek,
                ),
                Text(
                  _getKhmerMonthYear(
                    _calendarController.displayDate ?? DateTime.now(),
                  ),
                  style: TextStyle(
                    color: Color(blackColor),
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: _goToNextWeek,
                ),
              ],
            ),
            Expanded(
              child: SfCalendar(
                view: CalendarView.week,
                firstDayOfWeek: 1,
                todayHighlightColor: Color(blueColor),
                selectionDecoration: BoxDecoration(
                  color: Color(blueColor).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),

                onSelectionChanged: (CalendarSelectionDetails details) {
                  if (details is CalendarSelectionDetails) {
                    if (details.date != null && details.resource == null) {
                      // Start selecting
                      if (start == null) {
                        start = details.date;
                      } else {
                        end = details.date;
                        if (start!.isAfter(end!)) {
                          final temp = start;
                          start = end;
                          end = temp;
                        }
                        _openSelectedRangeModal();
                      }
                    }
                  }
                },
                viewHeaderStyle: ViewHeaderStyle(
                  dateTextStyle: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 18,
                    color: Color(blackColor),
                  ),
                  dayTextStyle: TextStyle(
                    color: Color(textColor),
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                headerStyle: CalendarHeaderStyle(
                  textStyle: TextStyle(
                    color: Color(blackColor),
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  backgroundColor: Color(bgColor),
                ),
                timeSlotViewSettings: TimeSlotViewSettings(
                  startHour: 6,
                  endHour: 22,
                  timeInterval: Duration(minutes: 60),
                  timeFormat: 'h:mm a',
                ),
                scheduleViewSettings: ScheduleViewSettings(
                  dayHeaderSettings: DayHeaderSettings()
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
