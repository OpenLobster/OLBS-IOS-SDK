import Foundation
import CoreData
import CoreLocation

private let _OLBSAPISharedInstance = OLBSAPI()

class OLBSAPI
{
    class var sharedInstance : OLBSAPI
    {
        return _OLBSAPISharedInstance
    }
    
    //AWSSNS Info and Control Flag
    var AWSEndPointArn:String = "" // OLBS use AWSEndPoint as UserToken for sending MSG
    var AWSReady = false // Use this flag to avoid calling OLBS before the AWSEnDPoint is obtained.
    
    // previous beacon information for beaconChanged detection
    var last_BUUID : String = ""
    var last_major : Int = 0
    var last_minor : Int = 0
    
    // OLBSAPI Info
    let SERVER_URL = "api.openlobster.org"
    let APIVersion = "v1"
    var OLBSAPIKey:String = ""
    
    // estimateOLBSLocation
    var UserToken:String = ""
    let SMode:Int = 1
    var DeviceID:String = ""
    var DeviceOS:Int = 1
    var Longitude:Float = -999.999999
    var Latitude:Float = -999.99999
    var Altitude:Float = -999999
    var NumBeacon:Int = 0
    var LocLabel:String = ""
    
    // return result of estimateOLBSLocation
    struct _OLBSLocation
    {
        var LUUID:String
        var Organization:String
        var Building:String
        var FloorLabel:String
        var FloorSeq:Int8
        var Room:String
        var FMapUUID:String
        var ux:Float
        var uy:Float
        
        init() {
            LUUID = ""
            Organization = ""
            Building = ""
            FloorLabel = ""
            FloorSeq = -128
            Room = ""
            FMapUUID = ""
            ux = -1.0
            uy = -1.0
        }
    }
    var OLBSLocation = _OLBSLocation();

    func beaconChanged(beacon:CLBeacon) -> Bool
    {
        if( (beacon.major.integerValue != last_major) || (beacon.minor.integerValue != last_minor))
        {
            last_major = beacon.major.integerValue
            last_minor = beacon.minor.integerValue
            
            return true
        }
        return false
    }
        
    func estimateOLBSLocation(Beacon:CLBeacon) -> JSON
    {
        if(AWSReady) // cannot perform OLBSAPI as AWSEndPoint is needed in OLBSAPI call
        {
            //let url = NSURL(string :"http://\(self.SERVER_URL)/\(self.APIVersion)/echo")
            let url = NSURL(string :"http://\(self.SERVER_URL)/\(self.APIVersion)/estimateOLBSLocation")
            let request:NSMutableURLRequest = NSMutableURLRequest(URL: url!)
            request.HTTPMethod = "POST"
            var response: NSURLResponse?

            var body:NSString = "{"
            body = "\(body)\"OLBSAPIKey\":\"\(OLBSAPIKey)\","
            body = "\(body)\"UserToken\":\"\(UserToken)\","
            body = "\(body)\"SMode\":\(SMode),"
            body = "\(body)\"DeviceID\":\"\(DeviceID)\","
            body = "\(body)\"DeviceOS\":\(DeviceOS),"
            body = "\(body)\"Longitude\":\(Longitude),"
            body = "\(body)\"Latitude\":\(Latitude),"
            body = "\(body)\"Altitude\":\(Altitude),"
            NumBeacon = 1
            body = "\(body)\"NumBeacon\":\(NumBeacon),"
            body = "\(body)\"LocLabel\":\"\(LocLabel)\","
            body = "\(body)\"ScanDetail\":[{"
            
            let BUUID = "\(Beacon.proximityUUID!.UUIDString)".stringByReplacingOccurrencesOfString("-", withString:"")

            body = "\(body)\"BUUID\":\"\(BUUID)\","
            body = "\(body)\"Major\":\"\(Beacon.major.integerValue)\","
            body = "\(body)\"Minor\":\"\(Beacon.minor.integerValue)\","
            body = "\(body)\"Tx\":-999,"
            body = "\(body)\"RSSI\":\"\(Beacon.rssi)\","
            body = "\(body)\"BName\":\"Unknown\","
            body = "\(body)\"BMac\":\"Unknown\""
            body = "\(body) }]}"
            
            request.HTTPBody = body.dataUsingEncoding(NSUTF8StringEncoding)
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
            var err: NSError?
            var dataVal: NSData =  NSURLConnection.sendSynchronousRequest(request, returningResponse: &response, error: &err/*nil*/)!
            if let httpResponse = response as? NSHTTPURLResponse {
                println(httpResponse.statusCode)
            }
            let json = JSON(data: dataVal)
            NSLog("estimateOLBSLocation: \(json)")

            OLBSLocation.LUUID = json["LUUID"].stringValue
            OLBSLocation.Organization = json["Organization"].stringValue
            OLBSLocation.Building = json["Building"].stringValue
            OLBSLocation.FloorLabel = json["FloorLabel"].stringValue
            OLBSLocation.FloorSeq = json["FloorSeq"].int8Value
            OLBSLocation.Room = json["Room"].stringValue
            OLBSLocation.FMapUUID = json["FMapUUID"].stringValue
            OLBSLocation.ux = json["ux"].floatValue
            OLBSLocation.uy = json["uy"].floatValue
            return true
        }
        return false
    }

    func sendMSG2UserAtLocationWithWebCallBack(LUUID:String, MSG:String) -> Int16
    {
        
        //let url = NSURL(string :"http://\(self.SERVER_URL)/\(self.APIVersion)/echo")
        let url = NSURL(string :"http://\(self.SERVER_URL)/\(self.APIVersion)/sendMSG2UserAtLocationWithWebCallBack")
        let request:NSMutableURLRequest = NSMutableURLRequest(URL: url!)
        request.HTTPMethod = "POST"
        var response: NSURLResponse?
        
        var body:NSString = "{"
        body = "\(body)\"OLBSAPIKey\":\"\(OLBSAPIKey)\","
        body = "\(body)\"LUUID\":\"\(LUUID)\","
        body = "\(body)\"MSG\":\"\(MSG)\"}"
        
        request.HTTPBody = body.dataUsingEncoding(NSUTF8StringEncoding)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        var err: NSError?
        var dataVal: NSData =  NSURLConnection.sendSynchronousRequest(request, returningResponse: &response, error: &err/*nil*/)!
        if let httpResponse = response as? NSHTTPURLResponse {
            println(httpResponse.statusCode)
        }
        let json = JSON(data: dataVal)
        NSLog("sendMSG2UserAtLocationWithWebCallBack: \(json)")
        
        return json["NumUsers"].int16Value
    }
}