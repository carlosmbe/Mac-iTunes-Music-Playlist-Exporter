//
//  ContentView.swift
//  Playlist Exporter
//
//  Created by Carlos Mbendera on 18/10/2022.
//

import AVFoundation
import iTunesLibrary
import SwiftUI

struct ContentView: View {
    
    //Empty Cause PlaceHolder
    @State private var Times = "00:00"
   
       
    @State private var playlistName = ""  //Placeholder Playlist name that will work on my device

    @State private var trackNames = [String]()
    @State private var artistNames = [String]()
    @State private var arrayOfSongPaths = [URL?]()
    @State private var convertAmount: Float = 0.0
    
    let playlists = try! ITLibrary(apiVersion: "1.1").allPlaylists
    var playlistNamesArray: [String] {
        return  playlists.compactMap{ $0.name }
        }

    var body: some View {
        
        VStack {
            
            Text("Hello, Curator!").font(.headline)
            
            Picker("Pick a Playlist to Compile", selection: $playlistName){
                ForEach(playlistNamesArray, id:\.self) {
                    Text($0)
                }
            }.onChange(of: playlistName) { getPlaylistsData(for: $0) }
            
            List(trackNames, id: \.self){
                Text($0)
            }
             .font(.body)
            
            Button("Combine Songs"){
                combineSongs()
            }.padding(.top)
              
            ProgressView("Compile Progress Bar", value: convertAmount, total: 1)
            
            Button("Open Results Folder"){
                let documentDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first! as NSURL
                NSWorkspace.shared.open(documentDirectoryURL as URL)
            }
            
            
            
        }.padding()
        .frame(minWidth: 700, minHeight: 500)
        
        .task{
            //Make sure default playlist matches with inital playlist name
         //MARK: temp remove getPlaylistsData()
        }
    }
    
    //Placeholder name here too
    func getPlaylistsData(for funcPlaylistName: String?){
        
        guard let funcPlaylistName = funcPlaylistName else{
            return
        }
        
        withAnimation{  trackNames.removeAll()  }
            artistNames.removeAll()
            arrayOfSongPaths.removeAll()
            Times = "00:00"
            convertAmount = 0.0
        
            
        var stuffIwant: ITLibPlaylist {
            for item in playlists{
                if item.name == funcPlaylistName{
                    return item
                }
            }
            return playlists[0]
        }
        
        
        for song in stuffIwant.items{
            withAnimation{
                trackNames.append(song.title)
                artistNames.append((song.artist?.name ?? song.album.albumArtist) ?? song.composer)
            }
            arrayOfSongPaths.append(song.location)
          //  print(song.title)
        }
       // print(arrayOfSongPaths.count)
    }
    

    
    func combineSongs(){
        //MARK:- FUNC START
        var recordingUrl = URL(string: "")
        
        let composition = AVMutableComposition()
        let compositionAudioTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        var canvaTracklist = ""
        for i in 0..<trackNames.count{
            compositionAudioTrack!.append(url: arrayOfSongPaths[i]!)
            Times = Times +  " \(artistNames[i]) - \(trackNames[i])" + "\n" + (compositionAudioTrack?.timeRange.end.positionalTime ?? "00:00")
            canvaTracklist = canvaTracklist + " \(trackNames[i]) \n"
        }
        
        //VERY IMPORTANT THAT THIS PATH IS MADE LIKE THIS CAUSE Permissions are a pain #Rookie
        let documentDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first! as NSURL
        recordingUrl = documentDirectoryURL.appendingPathComponent("\(playlistName) resultmerge.m4a")! as URL
        
        let tracklistDir = documentDirectoryURL.appendingPathComponent("\(playlistName) Tracklist (YT).txt")
        let canvaDir = documentDirectoryURL.appendingPathComponent("\(playlistName) Tracklist (Canva).txt")
        //TODO:- Let User pick output dir
        try?  canvaTracklist.write(to: canvaDir!, atomically: true, encoding: String.Encoding.utf8)
        try? Times.write(to: tracklistDir!, atomically: true, encoding: String.Encoding.utf8)
        
        var exportProgressBarTimer = Timer()
        
        if let assetExport = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A) {
            exportProgressBarTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
                // Get Progress
                convertAmount = Float((assetExport.progress))
            }
            assetExport.outputFileType = AVFileType.m4a
            assetExport.outputURL = recordingUrl
            assetExport.exportAsynchronously( completionHandler:    {
                switch assetExport.status {
                case AVAssetExportSession.Status.failed:
                    print("failed \(assetExport.error)")
                case AVAssetExportSession.Status.cancelled:
                    print("cancelled \(assetExport.error)")
                case AVAssetExportSession.Status.unknown:
                    print("unknown\(assetExport.error)")
                case AVAssetExportSession.Status.waiting:
                    print("waiting\(assetExport.error)")
                case AVAssetExportSession.Status.exporting:
                    print("exporting\(assetExport.error)")
                default:
                    print("COMPLETED YAY!!! NO WORRIES \n WOOO HOOOO")
                    exportProgressBarTimer.invalidate();
                    NSWorkspace.shared.open(documentDirectoryURL as URL)
                }
            })
        }//asset export end
        
    }  //MARK:- FUNC End

}


extension AVMutableCompositionTrack {
    func append(url: URL) {
        let newAsset = AVURLAsset(url: url)
        let range = CMTimeRangeMake(start: CMTime.zero, duration: newAsset.duration)
        let end = timeRange.end
        if let track = newAsset.tracks(withMediaType: AVMediaType.audio).first {
            try! insertTimeRange(range, of: track, at: end)
        }else{
            print("ERROR INSERTING")
        }
        
    }
}

extension CMTime {
    var roundedSeconds: TimeInterval {
        return seconds.rounded()
    }
    var hours:  Int { return Int(roundedSeconds / 3600) }
    var minute: Int { return Int(roundedSeconds.truncatingRemainder(dividingBy: 3600) / 60) }
    var second: Int { return Int(roundedSeconds.truncatingRemainder(dividingBy: 60)) }
    var positionalTime: String {
        return hours > 0 ?
            String(format: "%d:%02d:%02d",
                   hours, minute, second) :
            String(format: "%02d:%02d",
                   minute, second)
    }
}






struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
