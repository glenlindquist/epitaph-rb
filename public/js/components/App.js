import React from 'react';
import Civilization from './Civilization';
import * as Tone from "tone";

class App extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      civilizations: [],
      stardate: Math.floor(Math.random() * 99999) + 3000
    };
    this.newCivilization = this.newCivilization.bind(this);
    this.triggerEvent = this.triggerEvent.bind(this);
    this.acquireTechnology = this.acquireTechnology.bind(this);
    this.civilizationByName = this.civilizationByName.bind(this);
    this.updateCivilizations = this.updateCivilizations.bind(this);
    this.tick = this.tick.bind(this);
  }

  componentDidMount(){
    Tone.start()
    this.timerID = setInterval(
      () => this.tick(),
      1000
    );
    this.newCivilization();
  }

  componentDidUpdate(){
  }

  componentWillUnmount() {
    clearInterval(this.timerID);
  }

  playSound(pitch){
    const synth = new Tone.Synth().toMaster();
    synth.triggerAttackRelease(pitch, "8n")
  }


  tick(){
    // MAIN GAME UPDATE FUNCTION
    // @TODO: refactor
    this.state.civilizations.forEach((civ)=>{
      let eventOccurred = false;

      // randomly go through events and compare to event chance (do not select in same order)
      let events = Object.keys(civ.event_chances);
      events = events.sort(() => Math.random() - 0.5);
      for (const event of events){
        if (Math.random() < civ.event_chances[event]) {
          this.triggerEvent(civ.name, event);
          eventOccurred = true;
          console.log('event');
          break;
        }
      }

      // if no event do tech chance check
      if (!eventOccurred){
        if (Math.random() < (civ.tech_chance) && !!civ.available_technologies.length){
          let tech = civ.available_technologies[Math.floor(Math.random() * civ.available_technologies.length)]
          this.acquireTechnology(civ.name, tech);
          console.log("tech");
        }
      }
  
    });

    this.setState((state, props) => ({
      stardate: state.stardate + 1
    }));
  }

  newCivilization(){
    fetch('/new_civilization?stardate=' + this.state.stardate)
    .then((response) => {
      return response.json();
    })
    .then((newCivilization) => {
      if (!!this.civilizationByName(newCivilization.name)){
        // retry if civ with same name exists
        this.newCivilization();
      } else {
        this.updateCivilizations(newCivilization);
        this.playSound(newCivilization.notification_pitch)
      }
    });
  }

  triggerEvent(civName, eventName){
    console.log("event triggered")
    fetch('/trigger_event', {
      method: "post",
      body: JSON.stringify({
        civilization: this.civilizationByName(civName),
        event_name: eventName
      }),
      headers: { 'Content-type': 'application/json' }
    })
    .then((response) => {
      return response.json();
    })
    .then((civilization) => {
      this.updateCivilizations(civilization);
      this.playSound(civilization.notification_pitch)

    });
  }

  civilizationByName(civName){
    return this.state.civilizations.find(civ => civ.name === civName);
  }

  updateCivilizations(newCiv){
    this.setState((state, props) => ({
      civilizations: state.civilizations.
        filter(civ => civ.name != newCiv.name).
        concat(newCiv)
    }));
  }

  acquireTechnology(civName, techName, interference = false){
    console.log("tech acquired")

    let civ = this.civilizationByName(civName)
    if (interference){
      civ.last_interference = this.state.stardate;
    } else {
      this.playSound(civ.notification_pitch)
    }

    fetch('/acquire_technology', {
      method: "post",
      body: JSON.stringify({
        civilization: civ,
        technology_name: techName
      }),
      headers: { 'Content-type': 'application/json' }
    })
    .then((response) => {
      return response.json();
    })
    .then((newCiv) => {
      this.updateCivilizations(newCiv);
    });
  }

  render() {
    return (
      <div>
        <div>
          Stardate {this.state.stardate}
        </div>
        {this.state.civilizations.map((civilization) =>{
          let nextInterference = civilization.last_interference + 30;
          return (
            <Civilization
              key={civilization.name}
              onTechnologyClick={(civName, techName) => this.acquireTechnology(civName, techName, true)}
              name={civilization.name}
              availableTechnologies={civilization.available_technologies}
              history={civilization.history}
              canInterfere={this.state.stardate >= nextInterference}
              nextInterference={nextInterference}
            />
          );
        })}
      </div>
    );
  }
}

export default App;
