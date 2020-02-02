import React from 'react';

class Civilization extends React.Component {
  constructor(props) {
    super(props);
  }

  componentDidUpdate(){
    // @TODO: currently the whole app updates every tick
    // Is there a way to extract stardate state in a way that won't
    // force app to update (due to state change of stardate)
    console.log("civ updated.");
  }

  render() {

    let techCount = this.props.availableTechnologies.length

    let techSentence = this.props.availableTechnologies.map((tech, i)=>{
      if (i === 0) {
        // beginning
        return (
          <span key={tech}>
            <span key={tech + "sentence"} className="techSentenceStart">Would you like to teach the {this.props.name} the secrets of </span>
            <span className="techLink" key={tech + "link"} onClick={() => this.props.onTechnologyClick(this.props.name, tech)}>{tech}</span>
          </span>
        )
      } else if (i === techCount - 1) {
        // end
        return (
          <span key={tech}>
            {techCount == 2 ? <span key={tech + "joiner"}> or </span> : <span key={tech + "joiner"}>, or </span>}
            <span className="techLink" key={tech + "link"} onClick={() => this.props.onTechnologyClick(this.props.name, tech)}>{tech}</span>
          </span>
        )
      } else {
        // middle
        return (
          <span key={tech}>
            <span key={tech + "joiner"}>, </span>
            <span className="techLink" key={tech + "link"} onClick={() => this.props.onTechnologyClick(this.props.name, tech)}>{tech}</span>
          </span>
        )
      }
    }).concat(<span key="q">?</span>);

    return (
      <div>
        <div className="civDebugContainer">
          <h3>Civ: {this.props.name}</h3>
        </div>
        <div className="historyContainer">
          {this.props.history.map((event, i)=>{
            return(
              <div key={i} className="historyEvent">
                {event}
              </div>
            )
          })}
        </div>
        <div className="techContainer">
          {( this.props.canInterfere 
            ? 
              techCount > 0 ? techSentence : "No available technologies."
            :
              "Cannot interfere again until " + this.props.nextInterference + "."
          )}
        </div>
      </div>
    );
  }
}

export default Civilization;
