//
//  GCDBlackBox.swift
//  Virtual Tourist
//
//  Created by Matthew Gilman on 3/10/19.
//  Copyright © 2019 Matt Gilman. All rights reserved.
//

import Foundation
func performUIUpdatesOnMain(_ updates: @escaping () -> Void) {
    DispatchQueue.main.async {
        updates()
    }
}
