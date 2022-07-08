import React from "react";
import MintPage from "./MintPage";
import "./styles/mint.css";

function App() {
  return (
    <div className="background">
      <div className="container">
        <img className="headerImg" width="150" height="150" src="/config/images/glasses-square-guava.png" />
        <MintPage />
      </div>
    </div>
  );
}

export default App;