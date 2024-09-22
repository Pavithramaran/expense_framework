import 'package:flutter/material.dart';
import 'package:expences_tracker/widgets/new_expence.dart';
import 'package:expences_tracker/model/expence_model.dart';
import 'package:expences_tracker/widgets/chart/chart.dart';
import 'package:intl/intl.dart';
import '../main.dart';
import '../service/database_helper.dart';
import 'expences_item.dart';

class Expences extends StatefulWidget {
  final String userName;
  final String userEmail;

  const Expences({
    Key? key,
    required this.userName,
    required this.userEmail,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _ExpencesState();
  }
}

class _ExpencesState extends State<Expences> {
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  late List<ExpenceModel> _registeredExpences = [];
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  void _loadExpenses() async {
    final expenses = await DatabaseHelper.getAllExpences();
    if (expenses != null) {
      setState(() {
        _registeredExpences = expenses;
      });
    }
  }

  void _addExpence() {
    showModalBottomSheet(
      useSafeArea: true,
      isScrollControlled: true,
      context: context,
      builder: (context) => NewExpence(onAddExpence: _registerExpence),
    );
  }

  void _registerExpence(ExpenceModel expence) async {
    await DatabaseHelper.addExpense(expence);
    _loadExpenses();
  }

  void _onRemovedExpence(ExpenceModel expence, BuildContext context) async {
    await DatabaseHelper.deleteExpense(expence);
    setState(() {
      _registeredExpences.remove(expence);
    });

    _scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
    final snackBar = SnackBar(
      duration: const Duration(seconds: 3),
      content: const Text("Expense Deleted"),
      action: SnackBarAction(
        label: "Undo",
        onPressed: () async {
          int undoResult = await DatabaseHelper.addExpense(expence);
          if (undoResult > 0) {
            _loadExpenses();
          }
          _scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
        },
      ),
    );

    _scaffoldMessengerKey.currentState?.showSnackBar(snackBar);
  }

  void _navigateToUserInfo() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UserInfoPage(userName: widget.userName, userEmail: widget.userEmail)),
    );
  }

  void _filterByDate(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
  }

  void _downloadExpenses() {
    // Implement your download logic here
  }

  void _showExpensesPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ExpensesPage(
        registeredExpenses: _registeredExpences,
        onDateSelected: _filterByDate,
        selectedDate: _selectedDate,
        onDownloadExpenses: _downloadExpenses,
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Expences Tracker", style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            onPressed: _addExpence,
            icon: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(
                widget.userName,
                style: const TextStyle(color: Colors.black), // Set accountName text color to black
              ),
              accountEmail: Text(
                widget.userEmail,
                style: const TextStyle(color: Colors.black), // Set accountEmail text color to black
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.grey, // The color of the avatar circle
                child: Text(
                  widget.userName.isNotEmpty ? widget.userName[0] : '',
                  style: const TextStyle(fontSize: 40.0, color: Colors.white),
                ),
              ),
              decoration: const BoxDecoration(
                color: Colors.white, // Background color behind the avatar
              ),
            ),
            ExpansionTile(
              leading: const Icon(Icons.account_circle),
              title: const Text('Profile'),
              children: [
                ListTile(
                  title: const Text('User Info'),
                  onTap: _navigateToUserInfo,
                ),
                ListTile(
                  title: const Text('Expenses'),
                  onTap: _showExpensesPage,
                ),
              ],
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                // Implement logout logic (if needed)
                // Navigate back to LoginPage
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                      (Route<dynamic> route) => false, // Removes all routes
                );
              },
            ),
          ],
        ),
      ),

      body: Container(
        margin: const EdgeInsets.only(top: 10),
        child: Column(
          children: [
            Chart(expenses: _registeredExpences),
            Expanded(
              child: ListView.builder(
                itemCount: _registeredExpences.length,
                itemBuilder: (context, index) => Dismissible(
                  background: Container(
                    color: Colors.redAccent,
                    margin: EdgeInsets.symmetric(horizontal: Theme.of(context).cardTheme.margin!.horizontal),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    alignment: Alignment.centerLeft,
                    child: const Icon(Icons.delete),
                  ),
                  key: ValueKey(index),
                  onDismissed: (direction) {
                    _onRemovedExpence(_registeredExpences[index], context);
                  },
                  child: ExpencesItem(
                    expence: _registeredExpences[index],
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

// Full-screen Expenses Page
class ExpensesPage extends StatelessWidget {
  final List<ExpenceModel> registeredExpenses;
  final DateTime? selectedDate;
  final Function(DateTime) onDateSelected;
  final VoidCallback onDownloadExpenses;

  const ExpensesPage({
    Key? key,
    required this.registeredExpenses,
    required this.onDateSelected,
    required this.selectedDate,
    required this.onDownloadExpenses,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: onDownloadExpenses,
          ),
        ],
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () async {
              DateTime? date = await showDatePicker(
                context: context,
                initialDate: selectedDate ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                onDateSelected(date);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white, // Set button background to white
              foregroundColor: Colors.black, // Set button text to black
            ),
            child: Text(
              selectedDate == null
                  ? 'Select Date'
                  : 'Filter by ${DateFormat.yMd().format(selectedDate!)}',
            ),
          ),

          Expanded(
            child: ListView.builder(
              itemCount: registeredExpenses.length,
              itemBuilder: (context, index) {
                if (selectedDate != null && !registeredExpenses[index].date.isSameDay(selectedDate!)) {
                  return Container(); // Skip expenses not matching the selected date
                }
                return ExpencesItem(expence: registeredExpenses[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Extension method to compare dates
extension DateTimeComparison on DateTime {
  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }
}

class UserInfoPage extends StatefulWidget {
  final String userName;
  final String userEmail;

  const UserInfoPage({Key? key, required this.userName, required this.userEmail}) : super(key: key);

  @override
  _UserInfoPageState createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<UserInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.userName;
    // Initialize other controllers as needed
  }

  void _saveUserInfo() {
    if (_formKey.currentState!.validate()) {
      // Implement your save logic here
      Navigator.pop(context); // Go back after saving
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Info'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) => value!.isEmpty ? 'Enter your name' : null,
              ),
              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(labelText: 'Age'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Enter your age' : null,
              ),
              TextFormField(
                controller: _genderController,
                decoration: const InputDecoration(labelText: 'Gender'),
                validator: (value) => value!.isEmpty ? 'Enter your gender' : null,
              ),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address'),
                validator: (value) => value!.isEmpty ? 'Enter your address' : null,
              ),
              TextFormField(
                controller: _pincodeController,
                decoration: const InputDecoration(labelText: 'Pincode'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Enter your pincode' : null,
              ),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
                validator: (value) => value!.isEmpty ? 'Enter your phone number' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveUserInfo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white, // Button background color set to white
                  foregroundColor: Colors.black, // Button text color set to black
                ),
                child: const Text('Save'),
              ),

            ],
          ),
        ),
      ),
    );
  }
}


