import React from 'react';

class Civilization extends React.Component {
  constructor(props) {
    super(props);
  }

  componentDidUpdate(){
    // @TODO: currently the whole app updates every tick
    // Is there a way to extract stardate state in a way that won't
    // force app to update (due to state change of stardate)
  }

  render() {

    let opacity = (50 - this.props.position * 3) / 100.0;

    let techCount = this.props.availableTechnologies.length

    let techSentence = this.props.availableTechnologies.map((tech, i)=>{
      if (i === 0) {
        // beginning
        return (
          <span key={tech}>
            <span key={tech + "sentence"} className="tech-sentence-start">Would you like to teach the {this.props.name} the secrets of </span>
            <span className="tech-link" key={tech + "link"} onClick={() => this.props.onTechnologyClick(this.props.name, tech)}>{tech}</span>
          </span>
        )
      } else if (i === techCount - 1) {
        // end
        return (
          <span key={tech}>
            {techCount == 2 ? <span key={tech + "joiner"}> or </span> : <span key={tech + "joiner"}>, or </span>}
            <span className="tech-link" key={tech + "link"} onClick={() => this.props.onTechnologyClick(this.props.name, tech)}>{tech}</span>
          </span>
        )
      } else {
        // middle
        return (
          <span key={tech}>
            <span key={tech + "joiner"}>, </span>
            <span className="tech-link" key={tech + "link"} onClick={() => this.props.onTechnologyClick(this.props.name, tech)}>{tech}</span>
          </span>
        )
      }
    }).concat(<span key="q">?</span>);

    return (
      <div
        className={this.props.status === "extinct" ? "civ-container extinct" : "civ-container"}
        style={this.props.status === "extinct" ? {opacity:  opacity} : {}}
      >
        <div className="civ-name-container">
          <h3 className={this.props.status === "extinct" ? "extinct-civ-name": "civ-name"}>
            {this.props.name}
          </h3>
          <div
            className="planet"
            style={{
              backgroundColor: "#" + this.props.color,
              height: this.props.size,
              width: this.props.size
            }}>
          </div>
        </div>
        <hr className="under-name-line"></hr>
        <div className="history-container">
          {this.props.history.map((event, i)=>{
            return(
              <div key={i} className="history-event">
                {event}
              </div>
            )
          })}
        </div>
        <div className={this.props.status === "extinct" ? "tech-container-hidden" : "tech-container"}>
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
