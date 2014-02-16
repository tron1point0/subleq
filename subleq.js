module.exports = new (function() {
    var ORIG = new Array(0x1000);
    var MEM = new Array(0x1000);
    var PC = 0;

    function Leq(val) { return val & 0x80000000 || val === 0 };

    this.state = function() { return {PC: PC, MEM: MEM} };
    this.reset = function() { MEM = ORIG.slice(0); PC = 0 };

    this.load = function(what) {
        if (!util.isArray(what)) return false;
        ORIG = what;
        this.reset();
        return true;
    };

    this.step = function() {
        if (PC < 0 || PC >= MEM.length) return false;
        this.subleq();
        return this.state();
    }

    this.subleq = function () {
        MEM[MEM[1+PC]] -= MEM[MEM[PC]];
        PC = Leq(MEM[MEM[1+PC]]) ? MEM[2+PC] : 3+PC;
        return PC;
    };

    this.run = function () {
        while (this.step());
    };
})();
