module.exports = {
  mode: "development",
  entry: "./public/js/index.js",
  output: {
    "path": __dirname + "/public",
    "filename": "main.js"
  },
  module: {
    rules: [
      {
        test: /\.(js|jsx)$/,
        exclude: /(node_modules|bower_components)/,
        loader: "babel-loader",
        options: { presets: ["@babel/env"] }
      },
      {
        test: /\.css$/,
        use: ["style-loader", "css-loader"]
      }
    ]
  }  
}