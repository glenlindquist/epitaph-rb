import React from 'react';

class GameTimer extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      stardate: Math.floor(Math.random() * 99999) + 3000
    }

    this.tick = this.tick.bind(this);

  }

  componentDidMount(){
    this.timerID = setInterval(
      () => this.tick(),
      1000
    );
  }

  componentWillUnmount() {
    clearInterval(this.timerID);
  }

  tick(){
    // MAIN GAME UPDATE FUNCTION
    // @TODO: refactor
    this.props.civilizations.forEach((civ)=>{
      let eventOccurred = false;

      // randomly go through events and compare to event chance (do not select in same order)
      let events = Object.keys(civ.event_chances);
      events = events.sort(() => Math.random() - 0.5);
      for (const event of events){
        if (Math.random() < civ.event_chances[event]) {
          this.props.triggerEvent(civ.name, event);
          eventOccurred = true;
          console.log('event');
          break;
        }
      }

      // if no event do tech chance check
      if (!eventOccurred){
        if (Math.random() < (civ.tech_chance) && !!civ.available_technologies.length){
          let tech = civ.available_technologies[Math.floor(Math.random() * civ.available_technologies.length)]
          this.props.acquireTechnology(civ.name, tech);
          console.log("tech");
        }
      }
  
    });

    this.setState((state, props) => ({
      stardate: state.stardate + 1
    }));
  }

  render() {
    return (
      <div>
        Stardate {this.state.stardate}
      </div>
    );
  }
}

export default GameTimer;