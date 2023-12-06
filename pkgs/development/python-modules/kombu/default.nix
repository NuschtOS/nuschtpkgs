{
  lib,
  amqp,
  azure-identity,
  azure-servicebus,
  azure-storage-queue,
  backports-zoneinfo,
  boto3,
  buildPythonPackage,
  case,
  confluent-kafka,
  fetchPypi,
  hypothesis,
  kazoo,
  msgpack,
  pycurl,
  pymongo,
  #, pyro4
  pytest7CheckHook,
  pythonOlder,
  pyyaml,
  redis,
  sqlalchemy,
  typing-extensions,
  urllib3,
  vine,
}:

buildPythonPackage rec {
  pname = "kombu";
  version = "5.3.7";
  format = "setuptools";

  disabled = pythonOlder "3.8";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-ARxM2aNVwUod6NNdJXMUodJFbVK3FAOIVhrKw88al78=";
  };

  propagatedBuildInputs =
    [
      amqp
      vine
    ]
    ++ lib.optionals (pythonOlder "3.10") [ typing-extensions ]
    ++ lib.optionals (pythonOlder "3.9") [ backports-zoneinfo ];

  passthru.optional-dependencies = {
    msgpack = [ msgpack ];
    yaml = [ pyyaml ];
    redis = [ redis ];
    mongodb = [ pymongo ];
    sqs = [
      boto3
      urllib3
      pycurl
    ];
    zookeeper = [ kazoo ];
    sqlalchemy = [ sqlalchemy ];
    azurestoragequeues = [
      azure-identity
      azure-storage-queue
    ];
    azureservicebus = [ azure-servicebus ];
    confluentkafka = [ confluent-kafka ];
    # pyro4 doesn't suppport Python 3.11
    #pyro = [
    #  pyro4
    #];
  };

  nativeCheckInputs = [
    case
    hypothesis
    pytest7CheckHook
  ] ++ lib.flatten (with passthru.optional-dependencies; [ redis sqlalchemy sqs yaml ]); # avoid dependency on kazoo -> openjdk -> gtk2

  pythonImportsCheck = [ "kombu" ];

  disabledTests = [
    # Disable pyro4 test
    "test_driver_version"
  ];

  disabledTestPaths = [
    # disable azure because it no properly tests for the dependency
    "t/unit/transport/test_azurestoragequeues.py"
  ];

  meta = with lib; {
    description = "Messaging library for Python";
    homepage = "https://github.com/celery/kombu";
    changelog = "https://github.com/celery/kombu/blob/v${version}/Changelog.rst";
    license = licenses.bsd3;
    maintainers = with maintainers; [ fab ];
  };
}
