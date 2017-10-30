# InternetMap - General Testing Guidelines

### Testing Scenarios

#### High Priority
- Verify if the map is populated with data
- **Traceroute**: Verify if a traceroute can be performed
- **Historical Data**: Make sure that changing historical data increases/decreases the nodes on the map
- **Map Browsing**: Users should be able to zoom out/in and pan through the globe. 
#### Medium Priority
- Verify if all the submenus in the information menu (i icon) is loading the correct pages.
- Node Selection and Search should work as expected
- **Cross Device Compatibility**: Verify if the functions inside are stable in different screen sizes.
#### Low Priority
- Verify the integrity of user input in contact form
- Verify the integrity of the search node form
- Users should be able to select their location and search through the avaiable nodes

#### Standard Testing Guidelines

- App should generally follow platform UI best practices and guidelines
- Layout should work correctly on the supported device sizes (iPhone SE, iPhone 6+, iPhone X)
- Views should respond reasonably to slow and unavailable network conditions
- UI transitions should be smooth and to platform conventions
- Performance should be acceptable on slowest supported device (i.e. iPhone 5)
