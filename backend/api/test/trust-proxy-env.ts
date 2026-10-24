// Must be imported before AppModule: ConfigModule.forRoot() validates
// process.env when AppModule is first loaded.
process.env.RATE_LIMIT_MAX = "10"; // environmentSchema minimum
process.env.RATE_LIMIT_WINDOW_MS = "60000";
