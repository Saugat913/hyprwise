/// Every path in the app. Features build their own `RouteBase`s from these.
abstract final class AppRoutes {
  // Bottom tabs
  static const home = '/home';
  static const calendar = '/calendar';
  static const analytics = '/analytics';
  static const work = '/work';
  static const goals = '/goals';
  static const plan = '/goals';

  // Entry
  static const login = '/login';
  static const welcome = '/welcome';
  static const currency = '/currency';

  // Money
  static const money = '/money';
  static const addTransaction = '/money/add';
  static const transfers = '/transfers';

  // Accounts
  static const accounts = '/accounts';
  static const addAccount = '/accounts/add';
  static String account(int id) => '/accounts/$id';
  static const accountPattern = '/accounts/:id';

  // Work
  static const addJob = '/work/job/add';
  static const scheduleShift = '/work/shift/add';
  static const startShift = '/work/shift/start';
  static const liveShift = '/work/shift/live';
  static String shiftDone(int id) => '/work/shift/done/$id';
  static const shiftDonePattern = '/work/shift/done/:id';

  // Plan
  static const addGoal = '/plan/goal/add';

  // Alerts and assistant
  static const notifications = '/notifications';
  static const alerts = '/alerts';
  static const assistant = '/assistant';

  // Debts (Lending & Borrowing)
  static const debts = '/debts';
  static const addDebt = '/debts/add';

  // Categories & Merchants
  static const categories = '/categories';

  // Settings
  static const settings = '/settings';
  static const manageJobs = '/settings/jobs';
  static const currencySettings = '/settings/currency';
  static const backup = '/settings/backup';
  static const paywall = '/paywall';
}
