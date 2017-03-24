//
//  ViewController.swift
//  PushApp
//
//  Created by Sierra on 3/12/17.
//  Copyright © 2017 mobile. All rights reserved.
//

import UIKit
import UserNotifications

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func onClickButton(_ sender: Any) {
        self.createUserNotification()
    }
    
    func createUserNotification() {
    }

}

