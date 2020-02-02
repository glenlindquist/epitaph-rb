import React from 'react';
import Civilization from './Civilization';


class App extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      civilizations: []
    };
    this.newCivilization = this.newCivilization.bind(this);
    this.triggerEvent = this.triggerEvent.bind(this);
    this.acquireTechnology = this.acquireTechnology.bind(this);
    this.civilizationByName = this.civilizationByName.bind(this);
    this.updateCivilizations = this.updateCivilizations.bind(this);
  }

  componentDidMount(){
    this.newCivilization();
  }

  componentDidUpdate(){
  }

  newCivilization(){
    fetch('/new_civilization')
    .then((response) => {
      return response.json();
    })
    .then((newCivilization) => {
      // if (!!this.civilizationByName(newCivilization.name)){
      //   // retry if civ with same name exists
      //   this.newCivilization();
      // } else {
      //   this.updateCivilizations(newCivilization);
      // }
      this.updateCivilizations(newCivilization);
    });
  }

  triggerEvent(civilization, eventName){
    fetch('/trigger_event', {
      method: "POST",
      body: {
        civilization: civilization,
        event_name: EventName
      }
    })
    .then((response) => {
      return response.json();
    })
    .then((data) => {
      updateCivilization(data.civilization, data.event_text);
    });
  }

  civilizationByName(civName){
    return this.state.civilizations.find(civ => civ.name === civName);
  }

  updateCivilizations(newCiv){
    if(!!this.civilizationByName(newCiv.name)){
      // if existing civ
      let updated_civs = this.state.civilizations.
      filter(civ => civ.name != newCiv.name).
      concat(newCiv)

      this.setState({civilizations: updated_civs});
    } else {
      //if new civ
      this.setState({
        civilizations: this.state.civilizations.concat(newCiv) 
      });
    }

  }

  acquireTechnology(civName, techName){
    console.log(this.civilizationByName(civName))
    fetch('/acquire_technology', {
      method: "post",
      body: JSON.stringify({
        civilization: this.civilizationByName(civName),
        technology_name: techName
      }),
      headers: { 'Content-type': 'application/json' }
    })
    .then((response) => {
      return response.json();
    })
    .then((data) => {
      this.updateCivilizations(data.civilization);
      // @TODO: update text w/ data.text
    });
  }

  render() {
    return (
      <div>
        {this.state.civilizations.map((civilization, i) => 
          <Civilization
            key={i}
            onTechnologyClick={(civName, techName) => this.acquireTechnology(civName, techName)}
            name={civilization.name}
            available_technologies={civilization.available_technologies}
          />
        )}
        <h1> Hey :)</h1>
      </div>
    );
  }
}

export default App;
