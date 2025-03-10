import 'package:flutterdb/src/home_assistant_config.dart';
import 'package:home_assistant/home_assistant.dart';

// The app should never have to directly communicate with HA.
final HomeAssistant homeAssistant = HomeAssistant(
    baseUrl: HomeAssistantConfig.baseUrl,
    bearerToken: HomeAssistantConfig.token);

fetchData(HomeAssistant homeAssistant) async {
  print("The API is working: ${await homeAssistant.verifyApiIsWorking()}");

  //final Configuration config = await homeAssistant.fetchConfig();
  //print(config.toJson());

  //final List<Entity> entities = await homeAssistant.fetchStates();
  //print(entities.);

  final Entity entity =
      await homeAssistant.fetchState("light.esphome_web_60beb8_test_light");
  print(entity.attributes.brightness);

  //final List<Service> services = await homeAssistant.fetchServices();
  //print(services.first.domain);

  //Dummy Services
  homeAssistant.executeService("light.esphome_web_60beb8_test_light", "turn_on",
      additionalActions: {
        "brightness": 10,
      });

  await Future.delayed(Duration(seconds: 1));
}
