import React from 'react';
import ReactDOM from 'react-dom';
import App from './components/App';
import * as Tone from "tone";

document.body.addEventListener("click", ()=> Tone.start())

ReactDOM.render(
  <App
    synth={new Tone.Synth().toMaster()}
  />,
  document.getElementById('root')
);
