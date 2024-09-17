using UdonSharp;
using VRC.SDKBase;

public class Store : Notifyer
{
    [UdonSynced(UdonSyncMode.None)]
    private int _count = 0;

    public int count
    {
        get
        {
            return _count;
        }
    }

    private void transferOwner()
    {
        var player = Networking.LocalPlayer;
        var owner = Networking.GetOwner(gameObject);
        if (owner == null)
        {
            Networking.SetOwner(player, gameObject);
        }
    }

    private void sync()
    {
        var player = Networking.LocalPlayer;
        if (player.IsOwner(gameObject))
        {
            RequestSerialization();
            Notify();
        }
    }

    public override void OnDeserialization()
    {
        Notify();
    }
    public override void OnPlayerJoined(VRCPlayerApi player)
    {
        RequestSerialization();
    }

    public void Increment()
    {
        transferOwner();
        var player = Networking.LocalPlayer;

        if (player.IsOwner(gameObject))
        {
            _count++;
            sync();
        }
        else
        {
            SendCustomNetworkEvent(VRC.Udon.Common.Interfaces.NetworkEventTarget.Owner, "Increment");
            _count++;
            Notify();
        }
    }

    public void Decrement()
    {
        transferOwner();
        var player = Networking.LocalPlayer;

        if (player.IsOwner(gameObject))
        {
            _count--;
            sync();
        }
        else
        {
            SendCustomNetworkEvent(VRC.Udon.Common.Interfaces.NetworkEventTarget.Owner, "Decrement");
            _count--;
            Notify();
        }
    }
}