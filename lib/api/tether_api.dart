// The typed API clients, over one backend transport.
import '../backend/backend.dart';
import 'account_api.dart';
import 'care_records_api.dart';
import 'enrolments_api.dart';
import 'programme_events_api.dart';
import 'records_api.dart';

export 'account_api.dart';
export 'api_result.dart';
export 'care_records_api.dart';
export 'enrolments_api.dart';
export 'programme_events_api.dart';
export 'records_api.dart';

/// Every typed API client, sharing [transport]. The same in both backend
/// modes: only the transport differs.
class TetherApi {
  TetherApi(this.transport)
      : account = AccountApi(transport),
        enrolments = EnrolmentsApi(transport),
        events = ProgrammeEventsApi(transport),
        records = RecordsApi(transport),
        care = CareRecordsApi(transport);

  final BackendTransport transport;
  final AccountApi account;
  final EnrolmentsApi enrolments;
  final ProgrammeEventsApi events;
  final RecordsApi records;
  final CareRecordsApi care;
}
