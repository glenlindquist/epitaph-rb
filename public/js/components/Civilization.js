import React from 'react';

class Civilization extends React.Component {
  constructor(props) {
    super(props);
  }

  render() {

    let techCount = this.props.available_technologies.length

    let techSentence = this.props.available_technologies.map((tech, i)=>{
      if (i === 0) {
        // beginning
        return (
          <span key={tech}>
            <span key={tech + "sentence"} className="techSentenceStart">Would you like to teach the {this.props.name} the secrets of </span>
            <a key={tech + "link"} onClick={() => this.props.onTechnologyClick(this.props.name, tech)}>{tech}</a>
          </span>
        )
      } else if (i === techCount - 1) {
        // end
        return (
          <span key={tech}>
            {techCount == 2 ? <span key={tech + "joiner"}> or </span> : <span key={tech + "joiner"}>, or </span>}
            <a key={tech + "link"} onClick={() => this.props.onTechnologyClick(this.props.name, tech)}>{tech}</a>
          </span>
        )
      } else {
        // middle
        return (
          <span key={tech}>
            <span key={tech + "joiner"}>, </span>
            <a key={tech + "link"} onClick={() => this.props.onTechnologyClick(this.props.name, tech)}>{tech}</a>
          </span>
        )
      }
    });
    let butt = "butt";

    return (
      <div>
        <div className="civDebugContainer">
          <h3>Civ: {this.props.name}</h3>
        </div>
        <div className="historyContainer">
          
        </div>
        <div className="techContainer">
          {techSentence}
          {!!this.props.available_technologies.length ? "?" : null}
          {this.props.available_technologies.map((tech, i)=>
            ""
            // i === 0 ? (
            //   <span key={tech} className="sentence">
            //     Would you like to teach the {this.props.name} the secrets of 
            //     <a key={tech} onClick={() => this.props.onTechnologyClick(this.props.name, tech)}>{tech}</a>
            //   </span>
            // ) : (
            //   <span key={tech}>
            //     <a key={tech} onClick={() => this.props.onTechnologyClick(this.props.name, tech)}>{tech}</a>
            //   </span>
            // )
          )}
        </div>
      </div>
    );
  }
}

export default Civilization;
