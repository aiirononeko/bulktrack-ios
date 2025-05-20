import SwiftUI

struct SpotifyMusicView: View {
    @State private var isPlaying: Bool = false
    @State private var currentSongName: String = "ワークアウトミックス"
    @State private var artistName: String = "Spotify"
    @State private var volume: Double = 0.7
    
    var body: some View {
        VStack(spacing: 15) {
            // Spotifyロゴ風のデザイン
            Image(systemName: "music.note")
                .font(.system(size: 36))
                .foregroundColor(.green)
                .padding(.bottom, 5)
            
            // 曲情報
            Text(currentSongName)
                .font(.headline)
                .lineLimit(1)
            
            Text(artistName)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(1)
            
            // 再生コントロール
            HStack(spacing: 20) {
                Button(action: previousTrack) {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 22))
                }
                
                Button(action: togglePlayPause) {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.green)
                }
                
                Button(action: nextTrack) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 22))
                }
            }
            .padding(.vertical, 5)
            
            // 音量スライダー
            HStack {
                Image(systemName: "speaker.fill")
                    .foregroundColor(.secondary)
                
                Slider(value: $volume, in: 0...1)
                    .accentColor(.green)
                
                Image(systemName: "speaker.wave.3.fill")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .navigationTitle("音楽")
    }
    
    // 再生/一時停止の切り替え
    func togglePlayPause() {
        isPlaying.toggle()
        // ここで実際のSpotify APIとの連携コードが入る想定
    }
    
    // 前の曲
    func previousTrack() {
        // ここで実際のSpotify APIとの連携コードが入る想定
        // 仮実装として曲名を変更
        currentSongName = "前のトラック"
    }
    
    // 次の曲
    func nextTrack() {
        // ここで実際のSpotify APIとの連携コードが入る想定
        // 仮実装として曲名を変更
        currentSongName = "次のトラック"
    }
}

#Preview {
    SpotifyMusicView()
}
