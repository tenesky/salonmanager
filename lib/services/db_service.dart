import 'package:mysql1/mysql1.dart';

/// A simple database service to handle direct connections to the MySQL
/// database.  This class uses the mysql1 package to establish a
/// connection.  It is intended only for development purposes.  In
/// production you should implement a secure API layer between the
/// Flutter app and your database.
class DbService {
  // Connection settings for the remote MySQL database.  These
  // credentials are injected directly into the app.  Protect
  // sensitive information in a real project.
  static final ConnectionSettings settings = ConnectionSettings(
    host: '80.152.153.30',
    port: 3306,
    user: 'salonmanager-db',
    password: 'start#1234',
    db: 'salonmanagerdb',
  );

  /// Opens a new connection to the MySQL database.  The caller is
  /// responsible for closing the connection when finished.
  static Future<MySqlConnection> getConnection() async {
    return await MySqlConnection.connect(settings);
  }

  /// Example helper method for querying all stylists from the database.
  ///
  /// Returns a list of maps where each map contains stylist data.
  static Future<List<Map<String, dynamic>>> getStylists() async {
    final conn = await getConnection();
    final results = await conn.query('SELECT id, name, color FROM stylists');
    final stylists = results
        .map((row) => {
              'id': row['id'],
              'name': row['name'],
              'color': row['color'],
            })
        .toList();
    await conn.close();
    return stylists;
  }
}