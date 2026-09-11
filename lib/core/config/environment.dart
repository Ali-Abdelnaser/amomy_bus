enum EnvironmentType {
  dev,
  staging,
  prod;

  bool get isDev => this == EnvironmentType.dev;
  bool get isStaging => this == EnvironmentType.staging;
  bool get isProd => this == EnvironmentType.prod;
}
