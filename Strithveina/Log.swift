//
//  Log.swift
//  Strithveina
//
//  Created by Callum Mackenzie on 2024-10-29.
//

class Log {
    static let inst = Log()
    private static let RENDER_TAG = "RENDER";
    private static let GAME_VIEW_TAG = "GAME_VIEW";
    private static let MESH_TAG = "MESH";
    private static let CAMERA_TAG = "CAMERA";
    
    public static func render(_ msg: String) {
        Log.inst.printWithTag(tag: RENDER_TAG, msg: msg)
    }
    
    public static func renderError(_ msg: String) {
        Log.inst.errorWithTag(tag: RENDER_TAG, msg: msg)
    }
    
    public static func gameView(_ msg: String) {
        Log.inst.printWithTag(tag: GAME_VIEW_TAG, msg: msg)
    }
    
    public static func gameViewError(_ msg: String) {
        Log.inst.errorWithTag(tag: GAME_VIEW_TAG, msg: msg)
    }
    
    public static func meshError(_ msg: String) {
        Log.inst.errorWithTag(tag: MESH_TAG, msg: msg)
    }
    
    public static func camera(_ msg: String) {
        Log.inst.printWithTag(tag: CAMERA_TAG, msg: msg)
    }
    
    public static func cameraError(_ msg: String) {
        Log.inst.errorWithTag(tag: CAMERA_TAG, msg: msg)
    }
    
    
    private var shouldOutputSet: Set<String>
    
    private init() {
        self.shouldOutputSet = Set()
        self.shouldOutputSet.insert(Log.RENDER_TAG)
        self.shouldOutputSet.insert(Log.GAME_VIEW_TAG)
    }
    
    private func shouldOutput(tag: String) -> Bool {
        return self.shouldOutputSet.contains(tag)
    }
    
    private func printWithTag(tag: String, msg: String) {
        if (self.shouldOutput(tag: tag)) {
            print(tag + ": " + msg)
        }
    }
    
    private func errorWithTag(tag: String, msg: String) {
        print("ERROR IN " + tag + ": " + msg)
    }
}
