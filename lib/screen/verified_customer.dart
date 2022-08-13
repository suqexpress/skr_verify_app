import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoder/geocoder.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';
import 'package:skr_verify_app/model/addressModel.dart';
import 'package:skr_verify_app/model/customerListModel.dart';
import 'package:skr_verify_app/model/provider_model.dart';
import 'package:skr_verify_app/others/style.dart';
import 'package:skr_verify_app/others/widgets.dart';
import 'package:skr_verify_app/screen/main_screeen/search_screen.dart';
import 'package:skr_verify_app/search_field.dart';

class VerifiedShopsScreen extends StatefulWidget {
  const VerifiedShopsScreen({Key key}) : super(key: key);

  @override
  State<VerifiedShopsScreen> createState() => _VerifiedShopsScreenState();
}

class _VerifiedShopsScreenState extends State<VerifiedShopsScreen> {
  //List<CustomerListModel> customer=[];
  bool loading=false;
  bool isLoading=false;
  List<String> menuButton = ["DIRECTION",'EDIT SHOP'];
  var f = NumberFormat("###,###.0#", "en_US");

  setLoading(bool value){
    setState(() {
      loading=value;
    });
  }
   Coordinates userLatLng;
  getLocation()async{
    String actualAddress="Searching";
    var data =await Location().getLocation();
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
        actualAddress=addressList[3].shortName;
        Provider.of<ProviderModel>(context,listen: false).updateAddress(actualAddress);
        print("response ==== $_formattedAddress");
        _formattedAddress;
      }
    }
  }
  getCustomer()async{
    List<CustomerListModel>customer=[];
    Provider.of<ProviderModel>(context,listen: false).setLoading(true);
    var dio = Dio();
    setState(() {});
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
  Widget build(BuildContext context) {
    var customer=Provider.of<ProviderModel>(context).verified;
    var isLoading=Provider.of<ProviderModel>(context).isLoading;
    var media = MediaQuery.of(context).size;
    double height = media.height;
    var width = media.width;
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            child:Container(
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: Column(children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    InkWell(
                        onTap:()=>Navigator.push(context, MaterialPageRoute(builder: (context)=>SearchScreen(customerModel: customer, lat: 1.0, long: 1.0))),
                        child: Container(
                            width: width * 0.7,
                            child: SearchField(enable: false,onTap: (){}))),
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 1,horizontal: 5),
                      decoration: BoxDecoration(
                        color: themeColor1,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: IconButton(onPressed: (){
                        getLocation();
                        getCustomer();
                      },icon: Icon(Icons.refresh,color: Colors.white,),),),

                  ],
                ),

                isLoading?Container(
                  height: 480,
                  child: Shimmer.fromColors(
                    period: Duration(seconds: 1),
                    baseColor: Colors.grey.withOpacity(0.4),
                    highlightColor: Colors.grey.shade100,
                    enabled: true,
                    child: ListView.builder(
                      scrollDirection: Axis.vertical,
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: 4,
                      itemBuilder:
                          (BuildContext context, int index) {
                        return Column(
                          children: [
                            CustomShopContainerLoading(
                              height: height,
                              width: width,
                            ),
                            SizedBox(
                              height: height * 0.025,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ):Container(
                  width: width,
                  child:
                  Container(
                    padding: EdgeInsets.only(bottom: 60),
                    child: ListView.builder(
                        physics: NeverScrollableScrollPhysics(),
                        shrinkWrap: true,

                        itemCount: customer.length>10?10:customer.length,
                        itemBuilder:(context,index){
                          return
                            CustomerCard(
                              height: height,
                              width: width,
                              f: f,
                              menuButton: menuButton,
                              code: customer[index].id,
                              category: customer[index].custCat,
                              shopName: customer[index].custName,
                              address:customer[index].custAddress,
                              name: customer[index].custPrimNa,
                              phoneNo: customer[index].custPrimNb,
                              lastVisit: "--",
                              dues: "--",
                              lastTrans:"--",
                              outstanding: "--",
                              lat: customer[index].lat,
                              long: customer[index].long,
                              customerData: customer[index],
                              image:
                              "https://www.google.com/imgres?imgurl=https%3A%2F%2Fimages.indianexpress.com%2F2021%2F12%2Fdoctor-strange-2-1200.jpg&imgrefurl=https%3A%2F%2Findianexpress.com%2Farticle%2Fentertainment%2Fhollywood%2Fdoctor-strange-2-suggest-benedict-cumberbatch-sorcerer-supreme-might-lead-avengers-7698058%2F&tbnid=GxuE_SM1fXrAqM&vet=12ahUKEwjr4bj575_3AhVMxqQKHSC5BRAQMygBegUIARDbAQ..i&docid=6gb_YRZyTk5MWM&w=1200&h=667&q=dr%20strange&ved=2ahUKEwjr4bj575_3AhVMxqQKHSC5BRAQMygBegUIARDbAQ",
                              showLoading: (value) {
                                setState(() {
                                  isLoading = value;
                                });
                              },
                            );
                        }
                    ),
                  ),
                )

              ],),
            ),
          ),
          isLoading==false && customer.length<1 ?Center(
            child: Text("Shop Not Found"),
          ):Container()
        ],
      )
    );
  }
}
class CustomShopContainerLoading extends StatefulWidget {
  double height, width;

  CustomShopContainerLoading({
    this.height,
    this.width,
  });

  @override
  _CustomShopContainerLoadingState createState() =>
      _CustomShopContainerLoadingState();
}

class _CustomShopContainerLoadingState
    extends State<CustomShopContainerLoading> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              //height: height*0.15,
              //width: widget.width * 0.83,
              //color: Colors.red,
              child: Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: widget.height * 0.0055,
                    ),
                    Container(
                      height: widget.height * 0.025,
                      width: widget.width * 0.5,
                      color: Colors.red,
                    ),
                    SizedBox(
                      height: widget.height * 0.0075,
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          height: widget.height * 0.025,
                          width: widget.width * 0.05,
                          color: Colors.red,
                        ),
                        SizedBox(
                          width: widget.height * 0.01,
                        ),
                        Container(
                          height: widget.height * 0.025,
                          width: widget.width * 0.3,
                          color: Colors.red,
                        ),
                      ],
                    ),
                    SizedBox(
                      height: widget.height * 0.008,
                    ),
                    Padding(
                      padding: EdgeInsets.only(right: 0.0),
                      child: Container(
                        height: 1,
                        color: Color(0xffE0E0E0),
                      ),
                    ),
                    SizedBox(
                      height: widget.height * 0.008,
                    ),
                    Row(
                      children: [
                        Expanded(
                          flex: 12,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Container(
                                    height: widget.height * 0.025,
                                    width: widget.width * 0.05,
                                    color: Colors.red,
                                  ),
                                  SizedBox(
                                    width: widget.height  * 0.01,
                                  ),
                                  Container(
                                    height: widget.height * 0.025,
                                    width: widget.width * 0.2,
                                    color: Colors.red,
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: widget.height * 0.01,
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Container(
                                    height: widget.height * 0.025,
                                    width: widget.width * 0.05,
                                    color: Colors.red,
                                  ),
                                  SizedBox(
                                    width: widget.height * 0.01,
                                  ),
                                  Container(
                                    height: widget.height * 0.025,
                                    width: widget.width * 0.2,
                                    color: Colors.red,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Spacer(),
                        Expanded(
                          flex: 7,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 12.0, right: 8),
                            child: Container(
                              height: widget.height * 0.035,
                              width: widget.width * 0.22,
                              decoration: BoxDecoration(
                                  color: themeColor1 /*:Color(0xff1F92F6)*/,
                                  borderRadius: BorderRadius.circular(5)),
                              child: Center(
                                child: VariableText(
                                  text: '',
                                  fontsize: 11,
                                  fontcolor: Colors.white,
                                  weight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        )
                      ],
                    )
                  ],
                ),
              ),
            ),
          )

          /*   Container(
            height: widget.height * 0.14,
            width: widget.width * 0.28,
            color: Colors.red,
          ),*/
        ],
      ),
    );
  }
}