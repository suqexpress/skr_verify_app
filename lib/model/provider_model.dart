import 'package:flutter/material.dart';
import 'package:skr_verify_app/model/customerListModel.dart';

class ProviderModel extends ChangeNotifier{
  List<CustomerListModel> verified=[];
  List<CustomerListModel> unverified=[];
  List<CustomerListModel> incomplete=[];
  List<CustomerListModel> notFound=[];
  String actualAddress="Searching...";
  bool isLoading =false;

  getVerified(List<CustomerListModel> value){
    verified.clear();
    for(var i in value) {
      if(i.verified==1) {
        verified.add(i);
      }
    }
    notifyListeners();
  }
  getUnVerified(List<CustomerListModel> value){
    unverified.clear();
    for(var i in value) {
      if(i.verified==0) {
        unverified.add(i);
      }
    }
    notifyListeners();
  }
  getIncomplete(List<CustomerListModel> value){
    incomplete.clear();
    for(var i in value) {
      if(i.verified==3) {
        incomplete.add(i);
      }
    }
    notifyListeners();
  }
  getNotFound(List<CustomerListModel> value){
    notFound.clear();
    for(var i in value) {
      if(i.verified==2) {
        notFound.add(i);
      }
    }
    notifyListeners();
  }
  updateAddress(String value){
    actualAddress=value;
  }
  setLoading(bool value){
    isLoading=value;
  }
}