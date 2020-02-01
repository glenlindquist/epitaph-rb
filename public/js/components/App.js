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

  }

  componentDidMount(){
    this.newCivilization();
  }

  componentDidUpdate(){
    console.log("UPDATE");
  }

  newCivilization(){
    fetch('/new_civilization')
    .then((response) => {
      return response.json();
    })
    .then((new_civilization) => {
      this.setState({
        civilizations: this.state.civilizations.concat(new_civilization) 
      });
      this.forceUpdate();
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

  render() {
    return (
      <div>
        {this.state.civilizations.map((civilization) => 
          <Civilization key={civilization.name} {...civilization}/>
        )}
        <h1> Hey :)</h1>
      </div>
    );
  }
}

export default App;
