//
//  Data+Extension.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 08.08.2024.
//

import Foundation

extension Data {
    /// Data into file
    /// - Parameters:
    ///   - fileName: the Name of the file you want to write
    /// - Returns: Returns the URL where the new file is located in NSURL
    func dataToFile(fileName: String) -> URL? {
        
        // Make a constant from the data
        let data = self
        
        // Make the file path (with the filename) where the file will be loacated after it is created
        let filePath = getDocumentsDirectory().appendingPathComponent(fileName)
        let fileURL = URL(fileURLWithPath: filePath)
        
        do {
            // Write the file from data into the filepath
            try data.write(to: fileURL)
            
            // Returns the URL where the new file is located
            return fileURL
            
        } catch {
            // Prints the localized description of the error from the do block
            print("Error writing the file: \(error.localizedDescription)")
        }
        
        // Returns nil if there was an error in the do-catch -block
        return nil
        
    }
}
