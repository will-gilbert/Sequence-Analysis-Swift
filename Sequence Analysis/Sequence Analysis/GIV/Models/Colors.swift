//
//  GIVColors.swift
//  SA-GIV
//
//  Created by Will Gilbert on 8/4/21.
//

import SwiftUI

struct TriColor {
  let lighter: Color
  let base: Color
  let darker: Color
}


struct Colors {
  
  static let defaultColor = "aga 01"
  
  static let lighterTintBy = 25.0
  static let darkerTintBy = 25.0

  static var names: Dictionary<String, String> = [:]
  static var colors: Dictionary<String, TriColor> = [:]
  
  static func createNames() {
    if(Self.names.isEmpty) {
      Self.createHTMLColors()
      Self.createGrayScaleColors()
      Self.createCrayolaColors()
    }
  }
  
  static func getNames() -> [String] {
    Self.createNames()
    return Array(names.keys)
  }
  
  static func get(color: String) -> TriColor {
    Self.createNames()

    let colorNameKey = color.lowercased()
    
    // Handle "none", "transparent" or "clear"
    if(colorNameKey == "none" || colorNameKey == "transparent" || colorNameKey == "clear") {
      return TriColor(lighter: Color.clear, base: Color.clear, darker: Color.clear)
    }
    
    guard let hexCode = names[colorNameKey] else {
    return Self.get(color: Self.defaultColor)
  }
    
    if(colors[colorNameKey] == nil) {
      var rgbValue: UInt64 = 0
      Scanner(string: hexCode).scanHexInt64(&rgbValue)

      let baseColor = Color(.sRGB,
        red:   Double((rgbValue & 0xFF0000) >> 16) / 255.0,
        green: Double((rgbValue & 0x00FF00) >> 8) / 255.0,
        blue:  Double(rgbValue & 0x0000FF) / 255.0,
        opacity: Double(1.0))
      
      let triColor = TriColor(
        lighter: baseColor.lighter(by: Self.lighterTintBy),
        base: baseColor,
        darker: baseColor.darker(by: Self.darkerTintBy)
      )
      
      colors[colorNameKey] = triColor
    }

    return colors[colorNameKey]!
  }

    static func createGrayScaleColors() {
      names["aga 01"] = "eeeeee"
      names["aga 02"] = "dddddd"
      names["aga 03"] = "cccccc"
      names["aga 04"] = "bbbbbb"
      names["aga 05"] = "aaaaaa"
      names["aga 06"] = "999999"
      names["aga 07"] = "888888"
      names["aga 08"] = "777777"
      names["aga 09"] = "666666"
      names["aga 10"] = "555555"
      names["aga 11"] = "444444"
      names["aga 12"] = "222222"
      names["aga a"]  = "333333"
      names["aga a1"] = "ccccff"
      names["aga a2"] = "9999ff"
      names["aga a3"] = "6666cc"
      names["aga a4"] = "333399"
    }

  
 static func createCrayolaColors () {
   names["apricot"] = "ffd9b3"
   names["aquamarine"] = "7fffd4"
   names["bittersweet"] = "d94d00"
   names["black"] = "000000"
   names["blue"] = "4a4dc9"
   names["blue gray"] = "809eb8"
   names["blue green"] = "00b0a1"
   names["blue violet"] = "170054"
   names["brick"] = "ad0000"
   names["brown"] = "802600"
   names["burnt sienna"] = "964000"
   names["carnation"] = "ffbfbf"
   names["chinese red"] = "800d00"
   names["copper"] = "b3330a"
   names["cornflower"] = "a391ff"
   names["forest green"] = "005e00"
   names["gold"] = "ffcc00"
   names["goldenrod"] = "ffbf33"
   names["gray"] = "999999"
   names["gray blue"] = "598f9e"
   names["green"] = "00cc00"
   names["green blue"] = "0099a1"
   names["green yellow"] = "ccff00"
   names["lavender"] = "ffb3ff"
   names["lemon"] = "ffff4d"
   names["magenta"] = "ff00ff"
   names["mahogany"] = "b54000"
   names["maize"] = "ffbf1a"
   names["maroon"] = "c70042"
   names["melon"] = "ff5938"
   names["midnight"] = "001466"
   names["mulberry"] = "d60078"
   names["navy"] = "000094"
   names["olive"] = "d6d645"
   names["orange"] = "ff9900"
   names["orange red"] = "ff1a00"
   names["orange yellow"] = "ffbf00"
   names["orchid"] = "ff80ff"
   names["peach"] = "ffcca6"
   names["periwinkle"] = "b3b3d9"
   names["pine green"] = "12693d"
   names["plum"] = "470066"
   names["purple"] = "3d0054"
   names["raw sienna"] = "b04500"
   names["raw umber"] = "541400"
   names["red"] = "e00000"
   names["red orange"] = "ff4000"
   names["red violet"] = "de00ba"
   names["rose"] = "ff80b3"
   names["salmon"] = "ff9980"
   names["seafoam"] = "00ff66"
   names["sepia"] = "752633"
   names["silver"] = "a6a6a6"
   names["sky"] = "b8ebff"
   names["spring green"] = "00ff00"
   names["swamp fire"] = "de4700"
   names["tan"] = "ba6300"
   names["turquoise"] = "00cccc"
   names["violet blue"] = "330054"
   names["violet red"] = "e600ff"
   names["white"] = "ffffff"
   names["yellow"] = "ffff00"
   names["yellow green"] = "b3ff00"
   names["yellow orange"] = "ffa600"
 }


 // https://www.w3schools.com/tags/ref_colornames.asp
 static func createHTMLColors() {
   names["alice blue"] = "f0f8ff"
   names["antique white"] = "faebd7"
   names["aqua"] = "00ffff"
   names["aquamarine"] = "7fffd4"
   names["azure"] = "f0ffff"
   names["beige"] = "f5f5dc"
   names["bisque"] = "ffe4c4"
   names["black"] = "000000"
   names["blanched almond"] = "ffebcd"
   names["blue"] = "0000ff"
   names["blue violet"] = "8a2be2"
   names["brown"] = "a52a2a"
   names["burly wood"] = "deb887"
   names["cadet blue"] = "5f9ea0"
   names["chartreuse"] = "7fff00"
   names["chocolate"] = "d2691e"
   names["coral"] = "ff7f50"
   names["cornflower blue"] = "6495ed"
   names["cornsilk"] = "fff8dc"
   names["crimson"] = "dc143c"
   names["cyan"] = "00ffff"
   names["dark blue"] = "00008b"
   names["dark cyan"] = "008b8b"
   names["dark goldenrod"] = "b8860b"
   names["dark gray"] = "a9a9a9"
   names["dark grey"] = "a9a9a9"
   names["dark green"] = "006400"
   names["dark khaki"] = "bdb76b"
   names["dark magenta"] = "8b008b"
   names["dark olive green"] = "556b2f"
   names["dark orange"] = "ff8c00"
   names["dark orchid"] = "9932cc"
   names["dark red"] = "8b0000"
   names["dark salmon"] = "e9967a"
   names["dark sea green"] = "8fbc8f"
   names["dark slate blue"] = "483d8b"
   names["dark slate gray"] = "2f4f4f"
   names["dark slate grey"] = "2f4f4f"
   names["dark turquoise"] = "00ced1"
   names["dark violet"] = "9400d3"
   names["deep pink"] = "ff1493"
   names["deep sky blue"] = "00bfff"
   names["dim gray"] = "696969"
   names["dim grey"] = "696969"
   names["dodger blue"] = "1e90ff"
   names["fire brick"] = "b22222"
   names["floral white"] = "fffaf0"
   names["forest green"] = "228b22"
   names["fuchsia"] = "ff00ff"
   names["gainsboro"] = "dcdcdc"
   names["ghost white"] = "f8f8ff"
   names["gold"] = "ffd700"
   names["goldenrod"] = "daa520"
   names["gray"] = "808080"
   names["grey"] = "808080"
   names["green"] = "008000"
   names["green yellow"] = "adff2f"
   names["honey dew"] = "f0fff0"
   names["hot pink"] = "ff69b4"
   names["indian red"] = "cd5c5c"
   names["indigo"] = "4b0082"
   names["ivory"] = "fffff0"
   names["khaki"] = "f0e68c"
   names["lavender"] = "e6e6fa"
   names["lavender blush"] = "fff0f5"
   names["lawn green"] = "7cfc00"
   names["lemon chiffon"] = "fffacd"
   names["light blue"] = "add8e6"
   names["light coral"] = "f08080"
   names["light cyan"] = "e0ffff"
   names["light goldenrod yellow"] = "fafad2"
   names["light gray"] = "d3d3d3"
   names["light grey"] = "d3d3d3"
   names["light green"] = "90ee90"
   names["light pink"] = "ffb6c1"
   names["light salmon"] = "ffa07a"
   names["light sea green"] = "20b2aa"
   names["light sky blue"] = "87cefa"
   names["light slate gray"] = "778899"
   names["light slate grey"] = "778899"
   names["light steel blue"] = "b0c4de"
   names["light yellow"] = "ffffe0"
   names["lime"] = "00ff00"
   names["lime green"] = "32cd32"
   names["linen"] = "faf0e6"
   names["magenta"] = "ff00ff"
   names["maroon"] = "800000"
   names["medium aquamarine"] = "66cdaa"
   names["medium blue"] = "0000cd"
   names["medium orchid"] = "ba55d3"
   names["medium purple"] = "9370db"
   names["medium sea green"] = "3cb371"
   names["medium slate blue"] = "7b68ee"
   names["medium spring green"] = "00fa9a"
   names["medium turquoise"] = "48d1cc"
   names["medium violet red"] = "c71585"
   names["midnight blue"] = "191970"
   names["mint cream"] = "f5fffa"
   names["misty rose"] = "ffe4e1"
   names["moccasin"] = "ffe4b5"
   names["navajo white"] = "ffdead"
   names["navy"] = "000080"
   names["old lace"] = "fdf5e6"
   names["olive"] = "808000"
   names["olive drab"] = "6b8e23"
   names["orange"] = "ffa500"
   names["orange red"] = "ff4500"
   names["orchid"] = "da70d6"
   names["pale goldenrod"] = "eee8aa"
   names["pale green"] = "98fb98"
   names["pale turquoise"] = "afeeee"
   names["pale violet red"] = "db7093"
   names["papaya whip"] = "ffefd5"
   names["peach puff"] = "ffdab9"
   names["peru"] = "cd853f"
   names["pink"] = "ffc0cb"
   names["plum"] = "dda0dd"
   names["powder blue"] = "b0e0e6"
   names["purple"] = "800080"
   names["rebecca purple"] = "663399"
   names["red"] = "ff0000"
   names["rosy brown"] = "bc8f8f"
   names["royal blue"] = "4169e1"
   names["saddle brown"] = "8b4513"
   names["salmon"] = "fa8072"
   names["sandy brown"] = "f4a460"
   names["sea green"] = "2e8b57"
   names["seashell"] = "fff5ee"
   names["sienna"] = "a0522d"
   names["silver"] = "c0c0c0"
   names["sky blue"] = "87ceeb"
   names["slate blue"] = "6a5acd"
   names["slate gray"] = "708090"
   names["slate grey"] = "708090"
   names["snow"] = "fffafa"
   names["spring green"] = "00ff7f"
   names["steel blue"] = "4682b4"
   names["tan"] = "d2b48c"
   names["teal"] = "008080"
   names["thistle"] = "d8bfd8"
   names["tomato"] = "ff6347"
   names["turquoise"] = "40e0d0"
   names["violet"] = "ee82ee"
   names["wheat"] = "f5deb3"
   names["white"] = "ffffff"
   names["white smoke"] = "f5f5f5"
   names["yellow"] = "ffff00"
   names["yellow green"] = "9acd32"
 }

}

extension Color {

  func lighter(by percentage: Double = 30.0) -> Color {
      return self.adjust(by: abs(percentage) )
  }

  func darker(by percentage: Double = 30.0) -> Color {
      return self.adjust(by: -1 * abs(percentage) )
  }

  func adjust(by percentage: Double = 30) -> Color {
    
    let fraction = percentage/100
    
    if let rgb = self.cgColor?.components {

      let red = Double(rgb[0]) + fraction
      let green = Double(rgb[1]) + fraction
      let blue = Double(rgb[2]) + fraction
      let alpha = Double(rgb[3])

      return Color(red: min(red, 1.0),
                 green: min(green, 1.0),
                  blue: min(blue, 1.0),
               opacity: alpha)
    } else {
      return self
    }
  }
}
