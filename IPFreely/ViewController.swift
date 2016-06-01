//
//  ViewController.swift
//  IPFreely
//
//  Created by Ariel Elkin on 19/09/2015.
//  Copyright (c) 2015 Ariel. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    var userName: String?

    var originalIdeas = [String]()

    var myIdeas = [String]()

    var verbs = [String]()

    var nouns = [String]()

    var ideaToOwn = ""


    let tableView: UITableView

    let button = UIButton()

    var uploadPrompt: UIAlertView?

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        tableView = UITableView(frame: CGRectZero, style: .Plain)
        super.init(nibName: nil, bundle: nil)
    }


    override func loadView() {
        view = UIView()

        view.backgroundColor = UIColor.orangeColor()

        var viewsDict = [String: UIView]()

        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 100
        tableView.delegate = self
        tableView.dataSource = self
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.backgroundColor = UIColor.whiteColor()
        viewsDict["tableView"] = tableView
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)


        button.addTarget(self, action: #selector(buttonPressed), forControlEvents: .TouchUpInside)
        button.setTitle("Get Inspired", forState: .Normal)
        button.backgroundColor = UIColor.purpleColor()
        viewsDict["button"] = button
        button.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(button)

        var constraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[tableView]|", options: [], metrics: nil, views: viewsDict)
        view.addConstraints(constraints)

        constraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[button]|", options: [], metrics: nil, views: viewsDict)
        view.addConstraints(constraints)

        constraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[tableView][button]|", options: [], metrics: nil, views: viewsDict)
        view.addConstraints(constraints)

    }

    func buttonPressed() {
        if originalIdeas.isEmpty {
            getIdeas()
        }
        else {
            tableView.backgroundColor = UIColor.blackColor()
            generateIdeas()
        }
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        UIAlertView(title: "You're a genius", message: "Get ideas and prove it.", delegate: nil, cancelButtonTitle: "OK").show()

    }

    func getIdeas() {

        UIApplication.sharedApplication().networkActivityIndicatorVisible = true

        let getIdeasTask = NSURLSession.sharedSession().dataTaskWithURL(NSURL(string: "https://www.reddit.com/r/shittycrazyideas.json")!) {
            (data, response, error) in

            if let data = (try? NSJSONSerialization.JSONObjectWithData(data!, options: [])) as? NSDictionary {

                if let array = (data["data"] as? NSDictionary)?["children"] as? NSArray {

                    for ideaDict in array {
                        if let ideaText = (ideaDict["data"] as? NSDictionary)?["title"] as? String {

                            self.originalIdeas.append(ideaText)
                        }
                    }

                    for idea in self.originalIdeas {
                        self.processIdea(idea)
                    }


                    NSOperationQueue.mainQueue().addOperationWithBlock() {
                        self.tableView.reloadData()

                        UIApplication.sharedApplication().networkActivityIndicatorVisible = false

                        self.button.setTitle("Generate Ideas", forState: .Normal)
                        self.button.backgroundColor = UIColor.redColor()
                    }
                }
            }
        }

        getIdeasTask.resume()
    }

    func generateIdeas() {

        self.myIdeas = [String]()

        for ideaString in self.originalIdeas {

            let options: NSLinguisticTaggerOptions = [NSLinguisticTaggerOptions.OmitWhitespace, NSLinguisticTaggerOptions.OmitPunctuation, NSLinguisticTaggerOptions.JoinNames]
            let schemes = NSLinguisticTagger.availableTagSchemesForLanguage("en")
            let tagger = NSLinguisticTagger(tagSchemes: schemes, options: Int(options.rawValue))
            tagger.string = ideaString as String

            var newIdea = ""

            tagger.enumerateTagsInRange(NSMakeRange(0, (ideaString as NSString).length),
                scheme: NSLinguisticTagSchemeNameTypeOrLexicalClass,
                options: options) {
                    (tag, tokenRange, _, _) in

                    let token = (ideaString as NSString).substringWithRange(tokenRange)

                    newIdea = ideaString

                    switch tag {

                    case NSLinguisticTagVerb:

                        newIdea = newIdea.stringByReplacingOccurrencesOfString(token, withString: self.verbs.randomItem())

                    case NSLinguisticTagNoun, NSLinguisticTagPersonalName:

                        newIdea = newIdea.stringByReplacingOccurrencesOfString(token, withString: self.nouns.randomItem())
                        
                    default:
                        break
                    }
            }
            if newIdea != ideaString {
                self.myIdeas.append(newIdea)
            }
        }
        self.tableView.reloadData()
    }

    func processIdea(ideaString: String) {

        let options: NSLinguisticTaggerOptions = [NSLinguisticTaggerOptions.OmitWhitespace, NSLinguisticTaggerOptions.OmitPunctuation, NSLinguisticTaggerOptions.JoinNames]
        let schemes = NSLinguisticTagger.availableTagSchemesForLanguage("en")
        let tagger = NSLinguisticTagger(tagSchemes: schemes, options: Int(options.rawValue))
        tagger.string = ideaString

        tagger.enumerateTagsInRange(
            NSMakeRange(0, (ideaString as NSString).length),
            scheme: NSLinguisticTagSchemeNameTypeOrLexicalClass,
            options: options) {
                (tag, tokenRange, _, _) in

                let token = (ideaString as NSString).substringWithRange(tokenRange)

                print("\(token): \(tag)")


                switch tag {

                case NSLinguisticTagVerb:
                    self.verbs.append(token)

                case NSLinguisticTagNoun, NSLinguisticTagPersonalName:
                    self.nouns.append(token)

                default:
                    break
                }
        }
    }


    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

//CollectionView Data Source
extension ViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) 

        cell.textLabel?.numberOfLines = 0

        if !myIdeas.isEmpty {
            cell.textLabel?.text = myIdeas[indexPath.row]
        }
        else {
            cell.textLabel?.text = originalIdeas[indexPath.row]
        }

        return cell
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        if !myIdeas.isEmpty {
            return myIdeas.count
        }
        else {
            return originalIdeas.count
        }
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

        if myIdeas.isEmpty {

            UIAlertView(title: "NO!", message: "The idea needs to be your own. Knowumsaying?", delegate: nil, cancelButtonTitle: "Of course.").show()
            return
        }

        uploadPrompt = UIAlertView(title: "MINE!!!!", message: "Would you like to make this idea your own?", delegate: self, cancelButtonTitle: "NO!", otherButtonTitles: "I wanna watch the world burn.")
        uploadPrompt?.show()

        ideaToOwn = myIdeas[indexPath.row]
    }



    func askForName() {
        let enterNamePrompt = UIAlertView(title: "What's your name?", message: nil, delegate: self, cancelButtonTitle: "OK")
        enterNamePrompt.alertViewStyle = .PlainTextInput
        enterNamePrompt.show()
    }

    func ownIdea() {


        if let userName = userName {

            UIApplication.sharedApplication().networkActivityIndicatorVisible = true

            var dict = [String: String]()

            var cleanIdea = String(abs(ideaToOwn.hash))



            cleanIdea = "http://" + cleanIdea + ".com"

            dict["file_url"] = cleanIdea
            dict["title"] = "GREAT IDEA"
            dict["artist_name"] = userName

            let jsonData = try? NSJSONSerialization.dataWithJSONObject(dict, options: .PrettyPrinted)

            let request = NSMutableURLRequest(URL: NSURL(string: "https://www.ascribe.io/api/pieces/")!)

            request.setValue("Bearer 412ffb4f4374e83f9afb424566b2d2e2de5a9fd7", forHTTPHeaderField: "Authorization")

            print("\(NSString(data: jsonData!, encoding: NSUTF8StringEncoding)!)")


            request.HTTPBody = jsonData
            request.HTTPMethod = "POST"

            let ideaRegistrationTask = NSURLSession.sharedSession().dataTaskWithRequest(request) { (data, response, error) in

                NSOperationQueue.mainQueue().addOperationWithBlock() {

                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false

                    if let response = response as? NSHTTPURLResponse {
                        if !(200...299 ~= response.statusCode) {
                            UIAlertView(title: "Failed to make idea your own", message: "HTTP Error \(response.statusCode)", delegate: nil, cancelButtonTitle: "SHIT!").show()
                        }
                    } else if let error = error {
                        UIAlertView(title: "Failed to make idea your own", message: error.localizedDescription, delegate: nil, cancelButtonTitle: "SHIT!").show()
                    }
                    else {
                        UIAlertView(title: "The idea is yours now!!!", message: "This is yours: \(self.ideaToOwn)", delegate: nil, cancelButtonTitle: "SHIT!").show()
                    }
                }
            }
            ideaRegistrationTask.resume()
        }
    }
}

extension ViewController: UIAlertViewDelegate {
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {

        if alertView == uploadPrompt {
            if buttonIndex == 0 {
                return
            } else {
                if userName == nil {
                    askForName()
                } else {
                    ownIdea()
                }
            }
        }


        else {
            if let text = alertView.textFieldAtIndex(0)?.text {
                userName = text
                ownIdea()
            } else {
                askForName()
            }
        }
    }
}

extension Array {
    func randomItem() -> Element {
        let index = Int(arc4random_uniform(UInt32(self.count)))
        return self[index]
    }
}