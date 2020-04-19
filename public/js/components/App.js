import React from 'react';
import Civilization from './Civilization';

class App extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      civilizations: [],
      stardate: Math.floor(Math.random() * 99999) + 3000,
      soundOn: false
    };
    this.newCivilization = this.newCivilization.bind(this);
    this.triggerEvent = this.triggerEvent.bind(this);
    this.acquireTechnology = this.acquireTechnology.bind(this);
    this.civilizationByName = this.civilizationByName.bind(this);
    this.updateCivilizations = this.updateCivilizations.bind(this);
    this.tick = this.tick.bind(this);
    this.activeCivCount = this.activeCivCount.bind(this);
  }

  componentDidMount(){
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
    this.props.synth.triggerAttackRelease(pitch, "8n")
  }

  tick(){
    // MAIN GAME UPDATE FUNCTION
    // @TODO: refactor
    this.state.civilizations
      .filter((civ)=> civ.status != "extinct")
      .forEach((civ)=>{
      let eventOccurred = false;

      // randomly go through events and compare to event chance (do not select in same order)
      let events = Object.keys(civ.event_chances);
      events = events.sort(() => Math.random() - 0.5);
      for (const event of events){
        if (false) {
        // if (Math.random() < civ.event_chances[event]) {
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

    // make new civs
    let newCivChance = !!this.activeCivCount() ? 0.005 : 0.20
    if (Math.random() < newCivChance) {
      this.newCivilization();
    }

    this.setState((state, props) => ({
      stardate: state.stardate + 1
    }));
  }

  activeCivCount(){
    let count = 0;
    this.state.civilizations.forEach((civ) => {
      if (civ.status === "active") {
        count += 1;
      }
    });
    return count;
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
        .slice().sort((civ1, civ2) => civ2.discovery_date - civ1.discovery_date)
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
      <div className="container-fluid">
        <div className="stardate-clock">
          Stardate <span className="highlight">{this.state.stardate}</span>
        </div>
        <div className="all-civs-container">
          {this.state.civilizations.map((civilization, i) =>{
            let nextInterference = civilization.last_interference + 30;
            return (
              <Civilization
                key={civilization.name}
                onTechnologyClick={(civName, techName) => this.acquireTechnology(civName, techName, true)}
                name={civilization.name}
                availableTechnologies={civilization.available_technologies}
                status={civilization.status}
                history={civilization.history}
                canInterfere={this.state.stardate >= nextInterference}
                nextInterference={nextInterference}
                position={i}
                color={civilization.color}
                size={civilization.size}
              />
            );
          })}
        </div>
      </div>
    );
  }
}

export default App;
