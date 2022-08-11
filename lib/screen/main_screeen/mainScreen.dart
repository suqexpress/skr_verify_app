import 'dart:convert';
import 'dart:math' show acos, sin,cos,pi;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoder/geocoder.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:location/location.dart' as loc;
import 'package:http/http.dart' as http;
import 'package:skr_verify_app/model/addressModel.dart';
import 'package:skr_verify_app/model/customerListModel.dart';
import 'package:skr_verify_app/model/provider_model.dart';
import 'package:skr_verify_app/model/user_model.dart';
import 'package:skr_verify_app/others/style.dart';
import 'package:skr_verify_app/screen/notFoundScreen/notFoundScreen.dart';
import 'package:skr_verify_app/screen/unVerifiedScreen/unVerfiedScreen.dart';
import 'package:skr_verify_app/screen/verified_customer.dart';
import '../../search_field.dart';
var f = NumberFormat("###,###.0#", "en_US");
class MainScreen extends StatefulWidget {

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late List nearByCustomers=["0","0","0","0","0","0"];
  List<String> menuButton = ["DIRECTION",'EDIT SHOP'];
  bool isLoading=true;
  bool _serviceEnabled = false;
  var actualAddress = "Searching....";
   late Coordinates userLatLng;
  List<CustomerListModel> customer=[];
  bool loading=false;
  TextEditingController search=TextEditingController();



  setLoading(bool value){
    setState(() {
      loading=value;
    });
  }
  getLocation()async{
    String actualAddress="Searching";
    var data =await loc.Location().getLocation();
    List<AddressModel>addressList=[];
    userLatLng=Coordinates(data.latitude,data.longitude);
    String mapApiKey="AIzaSyDhBNajNSwNA-38zP7HLAChc-E0TCq7jFI";
    String _host = 'https://maps.google.com/maps/api/geocode/json';
    final url = '$_host?key=$mapApiKey&language=en&latlng=${userLatLng.latitude},${userLatLng.longitude}';
    print(url);
    if(userLatLng.latitude != null && userLatLng.longitude != null){
      var response1 = await http.get(Uri.parse(url));
      if(response1.statusCode == 200) {
        Map data = jsonDecode(response1.body);
        String _formattedAddress = data["results"][0]["formatted_address"];
        var address = data["results"][0]["address_components"];
        for(var i in address){
          addressList.add(AddressModel.fromJson(i));
        }
        actualAddress=addressList[3].shortName!;
        Provider.of<ProviderModel>(context,listen: false).updateAddress(actualAddress);
        print("response ==== $_formattedAddress");
        _formattedAddress;
      }
    }
  }
  getCustomer()async{
    Provider.of<ProviderModel>(context,listen: false).setLoading(true);
    var dio = Dio();
    Response response= await dio.get("https://erp.suqexpress.com/api/listcustomers").catchError((e){setLoading(false);
    Provider.of<ProviderModel>(context,listen: false).setLoading(false);
    });
    if (response.statusCode==200){
      // var data=jsonDecode(response.toString());
      debugPrint("get customer success");
      int i=0;
      for (var shop in response.data["data"]){
        double dist= Geolocator.distanceBetween(userLatLng.latitude, userLatLng.longitude, double.parse(shop['lat'].toString()=="null"?1.toString():shop['lat'].toString()),double.parse(shop['long'].toString()=="null"?1.toString():shop['long'].toString()));
        //calculateDistance(userLatLng.latitude, userLatLng.longitude, double.parse(shop['lat']), double.parse(shop['long'].toString()));
          customer.add(CustomerListModel.fromJson(shop, dist.toDouble()));
          debugPrint("distsnce: ${dist.toString()} $i ${customer[i].id}");
        i++;

      }
         customer.sort((a, b) => a.distance.compareTo(b.distance));
      Provider.of<ProviderModel>(context,listen: false).getNotFound(customer);
      Provider.of<ProviderModel>(context,listen: false).getUnVerified(customer);
      Provider.of<ProviderModel>(context,listen: false).getVerified(customer);
      Provider.of<ProviderModel>(context,listen: false).setLoading(false);

      setLoading(false);

    }else{
      Provider.of<ProviderModel>(context,listen: false).setLoading(false);
      setLoading(false);

    }

  }

  @override
  void initState() {
    getLocation();
    getCustomer();
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    final userData = Provider.of<UserModel>(context, listen: true);
    var actualAddress = Provider.of<ProviderModel>(context, listen: true).actualAddress;
    bool _isSearching=false;
    var media = MediaQuery.of(context).size;
    double height = media.height;
    var width = media.width;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor:themeColor1,
          title: Center(child: Text("DashBoard",style: TextStyle(color: Colors.white),)),
          actions: [
            Center(child: Text(actualAddress,style: TextStyle(color: Colors.white),)),
            SizedBox(width: 5,)
          ],
          bottom: TabBar(
            indicatorColor: Colors.white,
            tabs: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("UnVerified",style: TextStyle(color: Colors.white,fontSize: 15),)
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Verified",style: TextStyle(color: Colors.white,fontSize: 15),)
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Not Found",style: TextStyle(color: Colors.white,fontSize: 15),)
                ],
              ),
            ],
          ),
        ),
        drawer: Drawer(
          child: ListView(
            // Important: Remove any padding from the ListView.
            padding: EdgeInsets.zero,
            children: <Widget>[
              UserAccountsDrawerHeader(
                decoration: BoxDecoration(
                  color: themeColor1,
                ),
                accountName: Text(userData.data!.user!.firstName.toString()),
                accountEmail: Text(userData.data!.user!.phone.toString()),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.orange,
                  child: Text(userData.data!.user!.firstName.toString().substring(0,1),
                   // userData.firstName.toString().substring(0,1),
                    style: TextStyle(fontSize: 40.0,color: Colors.white),
                  ),
                ),
              ),
              ListTile(
                leading: Icon(Icons.home), title: Text("Logout"),
                onTap: () {
                },
              ),
              // ListTile(
              //   leading: Icon(Icons.settings), title: Text("Unverified Shops"),
              //   onTap: () {
              //     Navigator.push(context, MaterialPageRoute(builder: (context)=>UnVerifiedScreen()));
              //     },
              // ),
              // ListTile(
              //   leading: Icon(Icons.contacts), title: Text("Not Found"),
              //   onTap: () {
              //     Navigator.push(context, MaterialPageRoute(builder: (context)=>ShopNotFound()));
              //   },
              // ),
            ],
          ),
        ),
        body:TabBarView(
          children: [
            UnVerifiedShopScreen(),
            VerifiedShopsScreen(),
            NotFoundShopScreen(),
          ],
        )
      ),
    );
  }
}
