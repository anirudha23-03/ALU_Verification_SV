//`include "alu_environment.sv"

class alu_test;
//PROPERTIES
  //Virtual interfaces for driver, monitor and reference model
  virtual alu_if drv_vif;
  virtual alu_if mon_vif;
  virtual alu_if ref_vif;
  //Declaring handle for environment
  alu_environment env;

//METHODS
  //constructor to connect the virtual interfaces from driver, monitor and reference model to test
  function new(virtual alu_if drv_vif,
               virtual alu_if mon_vif,
               virtual alu_if ref_vif);
    this.drv_vif = drv_vif;
    this.mon_vif = mon_vif;
    this.ref_vif = ref_vif;
  endfunction

  //Task which builds the object for environment handle and calls the build and start methods of the environment
  task run();
    env = new(drv_vif,mon_vif,ref_vif);
    env.build;
    env.start;
  endtask
endclass
