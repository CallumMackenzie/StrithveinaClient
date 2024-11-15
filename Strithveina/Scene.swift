//
//  Scene.swift
//  Strithveina
//
//  Created by Callum Mackenzie on 2024-11-04.
//

protocol STSceneOwner {
    
    func setScene(scene: STScene?)
    
}

protocol STScene: STRenderable {
    
    func update(time: STTime)
    
}
